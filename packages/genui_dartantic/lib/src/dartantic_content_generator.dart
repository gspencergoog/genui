// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: specify_nonobvious_local_variable_types

import 'dart:async';
import 'dart:convert';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:json_schema/json_schema.dart';
import 'package:json_schema_builder/json_schema_builder.dart' as dsb;

import 'dartantic_content_converter.dart';
import 'dartantic_schema_adapter.dart';

/// A [ContentGenerator] that uses Dartantic AI to generate content.
///
/// This generator utilizes a [dartantic.Provider] to interact with various
/// AI providers (OpenAI, Anthropic, Google, Mistral, Cohere, Ollama) through
/// the dartantic_ai package.
///
/// The generator uses a "Prompt-First" approach:
/// 1. It injects the A2UI component catalog and rules into the system prompt.
/// 2. It requests a structured JSON response containing both the conversational
///    text and the UI actions (createSurface, updateComponents, etc.).
/// 3. It validates the generated JSON against the A2UI schema.
/// 4. If validation fails, it provides feedback to the model and retries.
///
/// This implementation is **stateless** - it does not maintain internal
/// conversation history. Instead, it uses the history provided by
/// [GenUiConversation] via the [sendRequest] method's `history` parameter.
class DartanticContentGenerator implements ContentGenerator {
  /// Creates a [DartanticContentGenerator] instance.
  ///
  /// - [provider]: The dartantic AI provider to use (e.g., `Providers.google`,
  ///   `Providers.openai`, `Providers.anthropic`).
  /// - [catalog]: The catalog of UI components available to the AI.
  /// - [systemInstruction]: Optional system instruction for the AI model.
  /// - [additionalTools]: Additional GenUI [AiTool] instances to make
  ///   available. Note: Core A2UI operations are handled via schema validation,
  ///   not tools.
  DartanticContentGenerator({
    required dartantic.Provider provider,
    required this.catalog,
    this.systemInstruction,
    this.modelName,
    this.additionalTools = const [],
    this.maxRetries = 3,
  }) {
    // Build the output schema dynamically based on the catalog
    final dsb.Schema actionSchema = _buildActionSchema(catalog);
    final outputSchemaBuilder = dsb.S.object(
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

    // Convert dsb.Schema to package:json_schema JsonSchema
    _outputSchema = JsonSchema.create(outputSchemaBuilder.toJson());

    // Convert additional tools to dartantic format
    // We do NOT add UpdateComponentsTool etc., as they are handled via
    // the output schema.
    final List<dartantic.Tool> dartanticTools = _convertTools(additionalTools);

    // Create agent with converted tools
    _agent = dartantic.Agent.forProvider(
      provider,
      chatModelName: modelName,
      tools: dartanticTools,
    );

    // Create system instructions including catalog and rules
    final catalogJson = const JsonEncoder.withIndent(
      '  ',
    ).convert((catalog.definition as dsb.ObjectSchema).toJson());

    _extraInstructions =
        '''
<component_catalog>
$catalogJson
</component_catalog>

<rules>
$_standardRules
</rules>

<output_schema>
${const JsonEncoder.withIndent('  ').convert(outputSchemaBuilder.toJson())}
</output_schema>
''';

    genUiLogger.info('Extra system instructions configured.');
  }

  /// The catalog of UI components available to the AI.
  final Catalog catalog;

  /// The system instruction to use for the AI model.
  final String? systemInstruction;

  /// The model name to use.
  final String? modelName;

  /// Additional tools to make available to the AI model.
  final List<AiTool<JsonMap>> additionalTools;

  /// Maximum number of validation retries.
  final int maxRetries;

  late final dartantic.Agent _agent;
  final DartanticContentConverter _converter = DartanticContentConverter();

  final _a2uiMessageController = StreamController<A2uiMessage>.broadcast();
  final _textResponseController = StreamController<String>.broadcast();
  final _errorController = StreamController<ContentGeneratorError>.broadcast();
  final _isProcessing = ValueNotifier<bool>(false);
  late final String _extraInstructions;
  late final JsonSchema _outputSchema;

  static const String _standardRules = '''
1. **Prompt-First Generation**: You must generate the UI structure directly in your response as JSON. Do NOT use tools or function calls to generate UI.
2. **Component Catalog**: You can only use components defined in the <component_catalog> provided above.
3. **Flattened Structure**: Components must be provided as a flat list in the `components` property of the `updateComponents` message.
4. **Data Binding**: Use `path` for values that should be bound to the data model. Use `value` (or specific type keys) for literal values.
5. **Strict JSON**: Your response must be valid JSON matching the <output_schema>.
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
      // Convert GenUI history to dartantic ChatMessage list
      final List<dartantic.ChatMessage> dartanticHistory = _converter.toHistory(
        history,
        systemInstruction: '$systemInstruction\n\n$_extraInstructions',
      );

      // Convert the current GenUI message into prompt text plus parts
      final ({String prompt, List<dartantic.Part> parts}) promptAndParts =
          _converter.toPromptAndParts(message);

      // We should never have tool calls or results in request message.
      assert(promptAndParts.parts.every((part) => part is! dartantic.ToolPart));

      genUiLogger.info(
        'Sending request to Dartantic: "${promptAndParts.prompt}"',
      );

      // Validation Loop
      var attempts = 0;
      String? currentPrompt = promptAndParts.prompt;
      List<dartantic.Part> currentParts = promptAndParts.parts;
      final currentHistory = <dartantic.ChatMessage>[
        ...dartanticHistory,
      ]; // Copy history

      while (attempts <= maxRetries) {
        attempts++;
        genUiLogger.fine('Attempt $attempts of ${maxRetries + 1}');

        final dartantic.ChatResult<Map<String, dynamic>> result = await _agent
            .sendFor<Map<String, dynamic>>(
              currentPrompt!,
              outputSchema: _outputSchema,
              history: currentHistory,
              attachments: currentParts,
            );

        final output = result.output;
        String? validationError;

        // Validating response content
        if (!output.containsKey('response') || output['response'] is! String) {
          validationError = "Output must contain a 'response' string field.";
        }

        if (output.containsKey('ui_actions')) {
          final actions = output['ui_actions'];
          if (actions is! List) {
            validationError =
                "Field 'ui_actions' must be a list of A2UI messages.";
          }
        }

        if (validationError != null) {
          genUiLogger.warning('Validation failed: $validationError');
          if (attempts > maxRetries) {
            throw ContentGeneratorError(
              'Max retries exceeded. Validation error: $validationError',
              StackTrace.current,
            );
          }
          // Add error to history/prompt and retry
          // We can append the error to history as a system or user message
          // mimicking a "Validation Error" feedback.
          // Since sendFor takes history, we can modify it.
          // But sendFor ALSO returns a ChatMessage we should ideally add to
          // history.
          // However, we are re-sending the *same* turn effectively?
          // No, we should treat it as a conversation turn:
          // User: request -> Model: invalid -> System: Error, try again.
          // dartantic.ChatResult gives us the message.

          // We can append the INVALID message to history
          // And then append a "Validation Failed" message from User/System.
          // Note: dartantic sendFor doesn't automatically update a persistent
          // history,
          // it takes history as arg.

          currentHistory.add(
            dartantic.ChatMessage(
              role: dartantic.ChatMessageRole.user,
              parts: [dartantic.TextPart(currentPrompt), ...currentParts],
            ),
          );
          currentHistory.add(
            dartantic.ChatMessage(
              role: dartantic.ChatMessageRole.model,
              parts: [
                dartantic.TextPart(
                  jsonEncode(output),
                ), // or however model replied
              ],
            ),
          );

          currentPrompt =
              'Validation failed: $validationError. Please correct the JSON.';
          currentParts = [];
          // Flatten prompt/parts for retry to just be the error message.

          continue;
        }

        // Processing Valid Output
        final responseText = output['response'] as String;
        _textResponseController.add(responseText);

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
                // We could treat this as a validation error too, but it passed
                // schema validation?
                // Maybe schema validation wasn't strict enough or
                // A2uiMessage.fromJson is stricter.
              }
            }
          }
        }

        genUiLogger.info('Received valid response from Dartantic.');
        return; // Success
      }
    } catch (e, st) {
      genUiLogger.severe('Error generating content', e, st);
      _errorController.add(ContentGeneratorError(e, st));
    } finally {
      _isProcessing.value = false;
    }
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

  /// Converts GenUI [AiTool] instances to dartantic [dartantic.Tool] instances.
  List<dartantic.Tool> _convertTools(List<AiTool<JsonMap>> tools) => tools
      .map(
        (aiTool) => dartantic.Tool(
          name: aiTool.name,
          description: aiTool.description,
          inputSchema: adaptSchema(aiTool.parameters),
          onCall: (Map<String, dynamic> args) async {
            genUiLogger.fine('Invoking tool: ${aiTool.name} with args: $args');
            final JsonMap result = await aiTool.invoke(args);
            genUiLogger.fine('Tool ${aiTool.name} returned: $result');
            return result;
          },
        ),
      )
      .toList();
}
