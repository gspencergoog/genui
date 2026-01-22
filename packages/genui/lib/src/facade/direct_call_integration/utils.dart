// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../model/a2ui_message.dart';
import '../../model/a2ui_schemas.dart';
import '../../model/catalog.dart';
import '../../model/tools.dart';
import '../../primitives/simple_items.dart';
import 'model.dart';

/// Prompt to be provided to the LLM about how to use the UI generation tools.
String genUiTechPrompt(List<String> toolNames) {
  final toolDescription = toolNames.length > 1
      ? 'the following UI generation tools: '
            '${toolNames.map((name) => '"$name"').join(', ')}'
      : 'the UI generation tool "${toolNames.first}"';

  return '''
To show generated UI, use $toolDescription.
When generating UI, always provide a unique $surfaceIdKey to identify the UI surface:

* To create new UI, use a new $surfaceIdKey.
* To update existing UI, use the existing $surfaceIdKey.

Use the root component id: 'root'.
Ensure one of the generated components has an id of 'root'.
''';
}

/// Converts a [Catalog] to a [GenUiFunctionDeclaration].
GenUiFunctionDeclaration catalogToFunctionDeclaration(
  Catalog catalog,
  String toolName,
  String toolDescription,
) {
  return GenUiFunctionDeclaration(
    description: toolDescription,
    name: toolName,
    parameters: A2uiSchemas.updateComponentsSchema(catalog),
  );
}

/// Parses a [ToolCall] into a [ParsedToolCall].
ParsedToolCall parseToolCall(ToolCall toolCall, String toolName) {
  assert(toolCall.name == toolName);

  // This function assumes the toolCall maps to an UpdateComponents message
  // roughly.
  // But we also need to ensure the surface is created.
  // We can emit both CreateSurface and UpdateComponents.

  final Map<String, Object?> messageJson = {'updateComponents': toolCall.args};
  final updateComponentsMessage = A2uiMessage.fromJson(messageJson);

  final surfaceId = (toolCall.args as JsonMap)[surfaceIdKey] as String;

  // We don't have catalogId here easily unless we infer or it's hardcoded.
  // For direct call integration, maybe we assume a default catalog or it's not
  // strictly checked by client if not using it for loading?
  // But CreateSurface requires catalogId.
  // Let's assume an empty string or 'default' if unknown, or maybe we shouldn't
  // emit CreateSurface here?
  // But A2uiMessageProcessor expects CreateSurface to behave correctly (init
  // notifier).
  // Let's use 'default' for now or passed in context if possible.
  // But this function signature doesn't have it.
  // However, `updateComponents` assumes surface exists.
  // If `parseToolCall` is used for the *first* call, it needs CreateSurface.

  final createSurfaceMessage = CreateSurface(
    surfaceId: surfaceId,
    catalogId: 'default', // Placeholder
    // root is implicit 'root'
  );

  return ParsedToolCall(
    messages: [createSurfaceMessage, updateComponentsMessage],
    surfaceId: surfaceId,
  );
}

/// Converts a catalog example to a [ToolCall].
ToolCall catalogExampleToToolCall(
  JsonMap example,
  String toolName,
  String surfaceId,
) {
  // Example is usually a list of components or a map with 'components'.
  // If example is just components list, we wrap it?
  // The catalog example usually matches the tool args.
  // A2uiSchemas.updateComponentsSchema structure:
  // { surfaceId, components: [...] }

  // If the example is just the components list (v0.8 style was sometimes
  // ambiguous), we need to ensure it matches v0.9 schema arg structure.
  // But usually `example` is the `args` map.

  // Create message to verify it parses?
  // final messageJson = {'updateComponents': example};
  // final updateMessage = A2uiMessage.fromJson(messageJson);

  return ToolCall(name: toolName, args: example);
}
