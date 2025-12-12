// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:uuid/uuid.dart';

import '../../core/prompt_fragments.dart';
import '../../model/a2ui_message.dart';
import '../../model/a2ui_protocol.dart';
import '../../model/catalog.dart';
import '../../model/ui_models.dart';
import '../../model/v0_9/messages.dart';
import '../../primitives/simple_items.dart';
import 'model.dart';

/// Generates a technical prompt for GenUI.
String genUiTechPrompt(List<String> toolNames) {
  return '''
${GenUiPromptFragments.basicChat}

You have access to the following tools: ${toolNames.join(', ')}.
Use these tools to generate UI components when requested.
''';
}

/// Converts a [Catalog] to a [GenUiFunctionDeclaration].
GenUiFunctionDeclaration catalogToFunctionDeclaration(
  Catalog catalog,
  String name,
  String description,
) {
  return GenUiFunctionDeclaration(
    name: name,
    description: description,
    parameters: catalog.definition.value,
  );
}

/// Parses a [ToolCall] into a [ParsedToolCall].
ParsedToolCall parseToolCall(ToolCall toolCall, String toolName) {
  final args = toolCall.args as JsonMap;
  final String surfaceId = const Uuid().v4();
  final messages = <A2uiMessage>[];

  if (args.containsKey('components')) {
    final Object? components = args['components'];
    if (components is List) {
      messages.add(
        UpdateComponents(
          surfaceId: surfaceId,
          components: components
              .cast<JsonMap>()
              .map(
                (e) => Component.fromJson(e, version: A2uiProtocolVersion.v0_9),
              )
              .toList(),
        ),
      );
    } else if (components is Map) {
      messages.add(
        UpdateComponents(
          surfaceId: surfaceId,
          components: components.values
              .cast<JsonMap>()
              .map(
                (e) => Component.fromJson(e, version: A2uiProtocolVersion.v0_9),
              )
              .toList(),
        ),
      );
    }
  }

  messages.insert(
    0,
    CreateSurface(surfaceId: surfaceId, catalogId: 'standard'),
  );

  return ParsedToolCall(messages: messages, surfaceId: surfaceId);
}
