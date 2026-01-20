// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart' hide TextPart;
import 'package:firebase_ai/firebase_ai.dart' as fb_ai;
// ignore: implementation_imports
import 'package:firebase_ai/src/api.dart' show ModalityTokenCount;
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart' hide Part;
import 'package:json_schema_builder/json_schema_builder.dart' as dsb;

import 'gemini_content_converter.dart';
import 'gemini_generative_model.dart';
import 'gemini_schema_adapter.dart';

/// A factory for creating a [GeminiGenerativeModelInterface].
///
/// This is used to allow for custom model creation, for example, for testing.
typedef GenerativeModelFactory =
    GeminiGenerativeModelInterface Function({
      required FirebaseAiContentGenerator configuration,
      Content? systemInstruction,
      List<Tool>? tools,
      ToolConfig? toolConfig,
    });

/// A [ContentGenerator] that uses the Firebase AI API to generate content.
class FirebaseAiContentGenerator implements ContentGenerator {
  /// Creates a [FirebaseAiContentGenerator] instance with specified
  /// configurations.
  FirebaseAiContentGenerator({
    required this.catalog,
    this.systemInstruction,
    this.outputToolName = 'provideFinalOutput',
    this.modelCreator = defaultGenerativeModelFactory,
    this.additionalTools = const [],
    this.maxRetries = 3,
  }) {
    // Build system instructions including catalog and rules
    final dsb.Schema definition = catalog.definition;
    final String catalogJson = const JsonEncoder.withIndent('  ').convert(
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

  /// A function to use for creating the model itself.
  final GenerativeModelFactory modelCreator;

  /// Additional tools to make available to the AI model.
  final List<AiTool> additionalTools;

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

      final dsb.Schema actionSchema = _buildActionSchema(catalog);
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

  static GeminiGenerativeModelInterface defaultGenerativeModelFactory({
    required FirebaseAiContentGenerator configuration,
    Content? systemInstruction,
    List<Tool>? tools,
    ToolConfig? toolConfig,
  }) {
    return GeminiGenerativeModel(
      FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash',
        systemInstruction: systemInstruction,
        tools: tools,
        toolConfig: toolConfig,
      ),
    );
  }

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
    final converter = GeminiContentConverter();
    final adapter = GeminiSchemaAdapter();

    try {
      final finalOutputAiTool = DynamicAiTool<Map<String, Object?>>(
        name: outputToolName,
        description:
            '''Returns the final output. Call this function when you are done with the current turn of the conversation.''',
        parameters: dsb.S.object(properties: {'output': outputSchema}),
        invokeFunction: (args) async => args,
      );

      final List<AiTool<JsonMap>> allTools = [
        ...additionalTools,
        finalOutputAiTool,
      ];

      final (
        :List<Tool>? generativeAiTools,
        :Set<String> allowedFunctionNames,
      ) = _setupToolsAndFunctions(
        availableTools: allTools,
        adapter: adapter,
      );

      var attempts = 0; // Validation retries
      var toolCycles = 0; // Regular tool cycles
      const maxToolCycles = 20;

      final Content systemInstructionWithRules = systemInstruction == null
          ? Content.system(_extraInstructions)
          : Content.system('$systemInstruction\n\n$_extraInstructions');

      final List<Content> mutableContent = converter.toFirebaseAiContent(
        messages,
      );

      final GeminiGenerativeModelInterface model = modelCreator(
        configuration: this,
        systemInstruction: systemInstructionWithRules,
        tools: generativeAiTools,
        toolConfig: ToolConfig(
          functionCallingConfig: FunctionCallingConfig.any(
            allowedFunctionNames.toSet(),
          ),
        ),
      );

      while (attempts <= maxRetries && toolCycles <= maxToolCycles) {
        GenerateContentResponse response;

        try {
          response = await model.generateContent(mutableContent);
          genUiLogger.finest(
            'Raw model response: ${_responseToString(response)}',
          );
        } catch (e, st) {
          genUiLogger.severe('Error generating content', e, st);
          rethrow;
        }

        if (response.usageMetadata != null) {
          inputTokenUsage += response.usageMetadata!.promptTokenCount ?? 0;
          outputTokenUsage += response.usageMetadata!.candidatesTokenCount ?? 0;
        }

        if (response.candidates.isEmpty) {
          genUiLogger.warning('Response has no candidates.');
          attempts++;
          continue;
        }

        final Candidate candidate = response.candidates.first;
        final List<FunctionCall> functionCalls = candidate.content.parts
            .whereType<FunctionCall>()
            .toList();

        if (functionCalls.isEmpty) {
          genUiLogger.warning(
            'No function calls returned (expected forced tool calling).',
          );
          attempts++;
          continue; // Retry
        }

        mutableContent.add(candidate.content);

        // Check for output tool
        final int outputCallIndex = functionCalls.indexWhere(
          (fc) => fc.name == outputToolName,
        );

        if (outputCallIndex != -1) {
          // Found output tool. Validate and return.
          final FunctionCall outputCall = functionCalls[outputCallIndex];
          final output = outputCall.args['output'] as Map<String, Object?>?;

          if (output == null) {
            genUiLogger.warning('Output tool called with null output.');
            attempts++;
            mutableContent.add(
              Content.model([
                const fb_ai.TextPart(
                  'Error: Output was null. Please provide valid JSON output.',
                ),
              ]),
            );
            continue;
          }

          // Validate structure
          if (!output.containsKey('response') ||
              output['response'] is! String) {
            genUiLogger.warning('Validation failed: Missing response field.');
            attempts++;
            mutableContent.add(
              Content.model([
                const fb_ai.TextPart("Error: Output missing 'response' field."),
              ]),
            );
            continue;
          }

          // Success!
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
          return;
        } else {
          // NO output tool, but valid other tools.
          toolCycles++;
          final functionResponseParts = <FunctionResponse>[];

          for (final call in functionCalls) {
            final AiTool<JsonMap> tool = allTools.firstWhere(
              (t) => t.name == call.name || t.fullName == call.name,
              orElse: () => throw Exception('Unknown tool ${call.name}'),
            );

            Map<String, Object?> result;
            try {
              result = await tool.invoke(call.args);
            } catch (e) {
              result = {'error': e.toString()};
            }
            functionResponseParts.add(FunctionResponse(call.name, result));
          }

          mutableContent.add(Content.functionResponses(functionResponseParts));
          continue; // Loop
        }
      }
    } catch (e, st) {
      genUiLogger.severe('Error in _generate loop', e, st);
      rethrow;
    }
  }

  ({List<Tool>? generativeAiTools, Set<String> allowedFunctionNames})
  _setupToolsAndFunctions({
    required List<AiTool> availableTools,
    required GeminiSchemaAdapter adapter,
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

    final functionDeclarations = <FunctionDeclaration>[];
    for (final AiTool<JsonMap> tool in uniqueAiToolsByName.values) {
      Schema? adaptedParameters;
      if (tool.parameters != null) {
        final GeminiSchemaAdapterResult result = adapter.adapt(
          tool.parameters!,
        );
        if (result.errors.isNotEmpty) {
          genUiLogger.warning(
            'Errors adapting parameters for tool ${tool.name}: '
            '${result.errors.join('\n')}',
          );
        }
        adaptedParameters = result.schema;
      }
      final Map<String, Schema>? parameters = adaptedParameters?.properties;
      functionDeclarations.add(
        FunctionDeclaration(
          tool.name,
          tool.description,
          parameters: parameters ?? const {},
        ),
      );
    }

    final List<Tool>? generativeAiTools = functionDeclarations.isNotEmpty
        ? [Tool.functionDeclarations(functionDeclarations)]
        : null;

    final allowedFunctionNames = <String>{
      ...uniqueAiToolsByName.keys,
      ...toolFullNames,
    };

    return (
      generativeAiTools: generativeAiTools,
      allowedFunctionNames: allowedFunctionNames,
    );
  }
}

String _usageMetadata(UsageMetadata? metadata) {
  if (metadata == null) return '';
  final buffer = StringBuffer();
  buffer.writeln('UsageMetadata(');
  buffer.writeln('  promptTokenCount: ${metadata.promptTokenCount},');
  buffer.writeln('  candidatesTokenCount: ${metadata.candidatesTokenCount},');
  buffer.writeln('  totalTokenCount: ${metadata.totalTokenCount},');
  buffer.writeln('  thoughtsTokenCount: ${metadata.thoughtsTokenCount},');
  buffer.writeln(
    '  toolUsePromptTokenCount: ${metadata.toolUsePromptTokenCount},',
  );
  buffer.writeln('  promptTokensDetails: [');
  for (final ModalityTokenCount detail
      in metadata.promptTokensDetails ?? <ModalityTokenCount>[]) {
    buffer.writeln('    ModalityTokenCount(');
    buffer.writeln('      modality: ${detail.modality},');
    buffer.writeln('      tokenCount: ${detail.tokenCount},');
    buffer.writeln('    ),');
  }
  buffer.writeln('  ],');
  buffer.writeln('  candidatesTokensDetails: [');
  for (final ModalityTokenCount detail
      in metadata.candidatesTokensDetails ?? <ModalityTokenCount>[]) {
    buffer.writeln('    ModalityTokenCount(');
    buffer.writeln('      ${detail.modality},');
    buffer.writeln('      ${detail.tokenCount},');
    buffer.writeln('    ),');
  }
  buffer.writeln('  ],');
  buffer.writeln('  toolUsePromptTokensDetails: [');
  for (final ModalityTokenCount detail
      in metadata.toolUsePromptTokensDetails ?? <ModalityTokenCount>[]) {
    buffer.writeln('    ModalityTokenCount(');
    buffer.writeln('      ${detail.modality},');
    buffer.writeln('      ${detail.tokenCount},');
    buffer.writeln('    ),');
  }
  buffer.writeln('  ],');
  buffer.writeln(')');
  return buffer.toString();
}

String _responseToString(GenerateContentResponse response) {
  final buffer = StringBuffer();
  buffer.writeln('GenerateContentResponse(');
  buffer.writeln('  usageMetadata: ${_usageMetadata(response.usageMetadata)},');
  buffer.writeln('  promptFeedback: ${response.promptFeedback},');
  buffer.writeln('  candidates: [');
  for (final Candidate candidate in response.candidates) {
    buffer.writeln('    Candidate(');
    buffer.writeln('      finishReason: ${candidate.finishReason},');
    buffer.writeln('      finishMessage: "${candidate.finishMessage}",');
    buffer.writeln('      content: Content(');
    buffer.writeln('        role: "${candidate.content.role}",');
    buffer.writeln('        parts: [');
    for (final Part part in candidate.content.parts) {
      if (part is fb_ai.TextPart) {
        buffer.writeln('          TextPart(text: "${part.text}"),');
      } else if (part is FunctionCall) {
        buffer.writeln('          FunctionCall(');
        buffer.writeln('            name: "${part.name}",');
        final String indentedLines = (const JsonEncoder.withIndent(
          '  ',
        ).convert(part.args)).split('\n').join('\n            ');
        buffer.writeln('            args: $indentedLines,');
        buffer.writeln('          ),');
      } else {
        buffer.writeln('          Unknown Part: ${part.runtimeType},');
      }
    }
    buffer.writeln('        ],');
    buffer.writeln('      ),');
    buffer.writeln('    ),');
  }
  buffer.writeln('  ],');
  buffer.writeln(')');
  return buffer.toString();
}
