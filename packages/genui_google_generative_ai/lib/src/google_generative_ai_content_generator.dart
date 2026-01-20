// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart'
    as google_ai;
import 'package:json_schema_builder/json_schema_builder.dart' as dsb;

import 'google_content_converter.dart';
import 'google_generative_service_interface.dart';
import 'google_schema_adapter.dart';

/// A factory for creating a [GoogleGenerativeServiceInterface].
///
/// This is used to allow for custom service creation, for example, for testing.
typedef GenerativeServiceFactory =
    GoogleGenerativeServiceInterface Function({
      required GoogleGenerativeAiContentGenerator configuration,
    });

/// A [ContentGenerator] that uses the Google Cloud Generative Language API to
/// generate content.
///
/// This generator uses a "Prompt-First" approach:
/// 1. It injects the A2UI component catalog and rules into the system prompt.
/// 2. It requests a structured JSON response containing both the conversational
///    text and the UI actions (createSurface, updateComponents, etc.).
/// 3. It validates the generated JSON against the A2UI schema.
/// 4. If validation fails, it provides feedback to the model and retries.
class GoogleGenerativeAiContentGenerator implements ContentGenerator {
  /// Creates a [GoogleGenerativeAiContentGenerator] instance with specified
  /// configurations.
  GoogleGenerativeAiContentGenerator({
    required this.catalog,
    this.systemInstruction,
    this.outputToolName = 'provideFinalOutput',
    this.serviceFactory = defaultGenerativeServiceFactory,
    this.additionalTools = const [],
    this.modelName = 'models/gemini-2.5-flash',
    this.apiKey,
    this.maxRetries = 3,
  }) {
    // Build system instructions including catalog and rules
    // cast definition to ObjectSchema to access toJson
    final definition = catalog.definition;
    final catalogJson = const JsonEncoder.withIndent('  ').convert(
      definition is dsb.ObjectSchema ? definition.toJson() : definition.value,
    );

    _extraInstructions =
        '''
<component_catalog>
$catalogJson
</component_catalog>

<rules>
$_standardRules
</rules>
''';
  }

  /// The catalog of UI components available to the AI.
  final Catalog catalog;

  /// The system instruction to use for the AI model.
  final String? systemInstruction;

  /// The name of an internal pseudo-tool used to retrieve the final structured
  /// output from the AI.
  final String outputToolName;

  /// A function to use for creating the service itself.
  final GenerativeServiceFactory serviceFactory;

  /// Additional tools to make available to the AI model.
  final List<AiTool> additionalTools;

  /// The model name to use (e.g., 'models/gemini-2.5-flash').
  final String modelName;

  /// The API key to use for authentication.
  final String? apiKey;

  /// Maximum number of validation retries.
  final int maxRetries;

  /// The total number of input tokens used by this client.
  int inputTokenUsage = 0;

  /// The total number of output tokens used by this client
  int outputTokenUsage = 0;

  final _a2uiMessageController = StreamController<A2uiMessage>.broadcast();
  final _textResponseController = StreamController<String>.broadcast();
  final _errorController = StreamController<ContentGeneratorError>.broadcast();
  final _isProcessing = ValueNotifier<bool>(false);
  late final String _extraInstructions;

  static const String _standardRules = '''
1. **Prompt-First Generation**: You must generate the UI structure directly in your response as JSON. Do NOT use tools or function calls to generate UI.
2. **Component Catalog**: You can only use components defined in the <component_catalog> provided above.
3. **Flattened Structure**: Components must be provided as a flat list in the `components` property of the `updateComponents` message.
4. **Data Binding**: Use `path` for values that should be bound to the data model. Use `value` (or specific type keys) for literal values.
5. **Strict JSON**: Your response must be valid JSON matching the output schema.
''';

  @override
  Stream<A2uiMessage> get a2uiMessageStream => _a2uiMessageController.stream;

  @override
  Stream<String> get textResponseStream => _textResponseController.stream;

  @override
  Stream<ContentGeneratorError> get errorStream => _errorController.stream;

  @override
  ValueListenable<bool> get isProcessing => _isProcessing;

  @override
  void dispose() {
    _a2uiMessageController.close();
    _textResponseController.close();
    _errorController.close();
    _isProcessing.dispose();
  }

  @override
  Future<void> sendRequest(
    ChatMessage message, {
    Iterable<ChatMessage>? history,
    A2UiClientCapabilities? clientCapabilities,
  }) async {
    _isProcessing.value = true;
    try {
      final messages = [...?history, message];

      // Build the output schema dynamically based on the catalog
      final actionSchema = _buildActionSchema(catalog);
      final outputSchema = dsb.S.object(
        properties: {
          'response': dsb.S.string(
            description: 'The conversational text response to the user.',
          ),
          'ui_actions': dsb.S.list(
            description:
                'List of UI actions to perform '
                '(createSurface, updateComponents, etc.)',
            items: actionSchema,
          ),
        },
        required: ['response'],
      );

      await _generate(messages: messages, outputSchema: outputSchema);
    } catch (e, st) {
      genUiLogger.severe('Error generating content', e, st);
      _errorController.add(ContentGeneratorError(e, st));
    } finally {
      _isProcessing.value = false;
    }
  }

  /// The default factory function for creating a [google_ai.GenerativeService].
  static GoogleGenerativeServiceInterface defaultGenerativeServiceFactory({
    required GoogleGenerativeAiContentGenerator configuration,
  }) {
    return GoogleGenerativeServiceWrapper(
      google_ai.GenerativeService.fromApiKey(configuration.apiKey),
    );
  }

  /// Builds the 'ui_actions' schema based on the catalog.
  dsb.Schema _buildActionSchema(Catalog catalog) {
    return dsb.S.combined(
      oneOf: [
        A2uiSchemas.createSurfaceSchema(),
        A2uiSchemas.updateComponentsSchema(catalog),
        A2uiSchemas.updateDataModelSchema(),
        A2uiSchemas.deleteSurfaceSchema(),
      ],
      description: 'An action to update the UI.',
    );
  }

  Future<void> _generate({
    required Iterable<ChatMessage> messages,
    required dsb.Schema outputSchema,
  }) async {
    final converter = GoogleContentConverter();
    final adapter = GoogleSchemaAdapter();

    final service = serviceFactory(configuration: this);

    try {
      // Create an "output" tool that copies its args into the output.
      // This is how we enforce structured output with Gemini.
      final finalOutputAiTool = DynamicAiTool<Map<String, Object?>>(
        name: outputToolName,
        description:
            '''Returns the final output. Call this function when you are done with the current turn of the conversation.''',
        parameters: dsb.S.object(properties: {'output': outputSchema}),
        invokeFunction: (args) async => args,
      );

      final allTools = [...additionalTools, finalOutputAiTool];

      final (:tools, :allowedFunctionNames) = _setupToolsAndFunctions(
        availableTools: allTools,
        adapter: adapter,
      );

      var attempts = 0;

      // Build system instruction if provided
      final systemInstructionContent = <google_ai.Content>[
        google_ai.Content(
          parts: [
            google_ai.Part(text: '$systemInstruction\n\n$_extraInstructions'),
          ],
        ),
      ];

      // A local copy of the incoming messages which is updated with
      // tool results as they are generated.
      final content = converter.toGoogleAiContent(messages);

      if (content.isEmpty) {
        // Should not happen if messages is not empty, but ensure we have at
        // least one message.
        // If history is empty and message is internally handled?
      }

      while (attempts <= maxRetries) {
        attempts++;
        genUiLogger.fine('Attempt $attempts of ${maxRetries + 1}');

        final request = google_ai.GenerateContentRequest(
          model: modelName,
          contents: [...systemInstructionContent, ...content],
          tools: tools ?? [],
          toolConfig: google_ai.ToolConfig(
            functionCallingConfig: google_ai.FunctionCallingConfig(
              mode: google_ai.FunctionCallingConfig_Mode.any,
              allowedFunctionNames: [
                outputToolName,
              ], // Force successful structure
            ),
          ),
        );

        final response = await service.generateContent(request);

        if (response.usageMetadata != null) {
          inputTokenUsage += response.usageMetadata!.promptTokenCount;
          outputTokenUsage += response.usageMetadata!.candidatesTokenCount;
        }

        if (response.candidates.isEmpty) {
          genUiLogger.warning('Response has no candidates.');
          if (attempts > maxRetries) throw Exception('No candidates returned.');
          continue;
        }

        final candidate = response.candidates.first;
        final parts = candidate.content?.parts ?? [];
        final functionCalls = parts
            .where((p) => p.functionCall != null)
            .map((p) => p.functionCall!)
            .toList();

        // Provide a dummy name if no function call found or if orElse is hit
        // (though orElse won't be hit if list not empty)
        // If list is empty, we set functionCall to null.

        final functionCall = functionCalls.isEmpty
            ? null
            : functionCalls.firstWhere(
                (fc) => fc.name == outputToolName,
                orElse: () => google_ai.FunctionCall(name: 'unknown'),
              );

        if (functionCall == null || functionCall.name != outputToolName) {
          genUiLogger.warning('Model did not call output tool.');
          if (attempts > maxRetries) {
            throw Exception('Model failed to call output tool.');
          }
          continue;
        }

        // Extract output
        final argsMap = functionCall.args?.toJson() as Map<String, Object?>?;
        final output = argsMap?['output'] as Map<String, Object?>?;

        if (output == null) {
          genUiLogger.warning('Output tool called with null output.');
          continue;
        }

        // Validate structure
        if (!output.containsKey('response') || output['response'] is! String) {
          genUiLogger.warning('Validation failed: Missing response field.');
          continue;
        }

        // Process valid output
        _textResponseController.add(output['response'] as String);

        if (output.containsKey('ui_actions')) {
          final actions = output['ui_actions'] as List;
          for (final actionData in actions) {
            if (actionData is Map<String, dynamic>) {
              try {
                final message = A2uiMessage.fromJson(actionData);
                _a2uiMessageController.add(message);
              } catch (e) {
                genUiLogger.severe(
                  'Error parsing A2UI message: $actionData',
                  e,
                );
              }
            }
          }
        }

        return; // Success
      }
    } finally {
      service.close();
    }
  }

  ({List<google_ai.Tool>? tools, Set<String> allowedFunctionNames})
  _setupToolsAndFunctions({
    required List<AiTool> availableTools,
    required GoogleSchemaAdapter adapter,
  }) {
    final uniqueAiToolsByName = <String, AiTool>{};
    final toolFullNames = <String>{};
    for (final tool in availableTools) {
      if (uniqueAiToolsByName.containsKey(tool.name)) {
        throw Exception('Duplicate tool ${tool.name} registered.');
      }
      uniqueAiToolsByName[tool.name] = tool;
      if (tool.name != tool.fullName) {
        if (toolFullNames.contains(tool.fullName)) {
          throw Exception('Duplicate tool ${tool.fullName} registered.');
        }
        toolFullNames.add(tool.fullName);
      }
    }

    final functionDeclarations = <google_ai.FunctionDeclaration>[];
    for (final tool in uniqueAiToolsByName.values) {
      google_ai.Schema? adaptedParameters;
      if (tool.parameters != null) {
        final result = adapter.adapt(tool.parameters!);
        if (result.errors.isNotEmpty) {
          genUiLogger.warning(
            'Errors adapting parameters for tool ${tool.name}: '
            '${result.errors.join('\n')}',
          );
        }
        adaptedParameters = result.schema;
      }
      functionDeclarations.add(
        google_ai.FunctionDeclaration(
          name: tool.name,
          description: tool.description,
          parameters: adaptedParameters,
        ),
      );
    }

    final tools = functionDeclarations.isNotEmpty
        ? [google_ai.Tool(functionDeclarations: functionDeclarations)]
        : null;

    final allowedFunctionNames = <String>{
      ...uniqueAiToolsByName.keys,
      ...toolFullNames,
    };

    return (tools: tools, allowedFunctionNames: allowedFunctionNames);
  }
}
