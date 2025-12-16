// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/genui_host.dart';
import '../../model/data_model.dart';
import '../../model/ui_models.dart';
import '../../primitives/logging.dart';
import '../../primitives/simple_items.dart';
import '../a2ui_message.dart';
import '../a2ui_protocol.dart';
import '../catalog.dart';
import '../tools.dart';
import 'messages.dart';
import 'schemas.dart';

/// Implementation of the A2UI protocol for version 0.9.
class A2uiProtocolV09 implements A2uiProtocol {
  /// Creates an instance of [A2uiProtocolV09].
  const A2uiProtocolV09();

  @override
  A2uiProtocolVersion get version => A2uiProtocolVersion.v0_9;

  @override
  Stream<A2uiMessage> parsePayload(Object payload) {
    if (payload is String) {
      final String line = payload.trim();
      if (line.isEmpty) return const Stream.empty();
      try {
        final Object? json = jsonDecode(line);
        if (json is JsonMap) {
          return Stream.value(parseJson(json));
        }
      } catch (_) {
        // Not a JSON object
      }
    } else if (payload is JsonMap) {
      try {
        return Stream.value(parseJson(payload));
      } catch (_) {}
    }
    return const Stream.empty();
  }

  @override
  A2uiMessage parseJson(JsonMap json) {
    if (json.containsKey('updateComponents')) {
      return UpdateComponents.fromJson(json['updateComponents'] as JsonMap);
    }
    if (json.containsKey('updateDataModel')) {
      return UpdateDataModel.fromJson(json['updateDataModel'] as JsonMap);
    }
    if (json.containsKey('createSurface')) {
      return CreateSurface.fromJson(json['createSurface'] as JsonMap);
    }
    // Shared
    if (json.containsKey('deleteSurface')) {
      return DeleteSurface.fromJson(json['deleteSurface'] as JsonMap);
    }
    if (json.containsKey('error')) {
      return ErrorMessage.fromJson(json['error'] as JsonMap);
    }
    throw FormatException('Unknown A2UI V0.9 message type: $json');
  }

  @override
  List<AiTool> getTools(Catalog catalog, void Function(A2uiMessage) onMessage) {
    return const [];
  }

  @override
  String? getSystemPreamble(Catalog catalog) {
    final Map<String, dynamic> catalogSchema = A2uiSchemas.buildCatalogSchema(
      catalog,
    );
    final String catalogJson = const JsonEncoder.withIndent(
      '  ',
    ).convert(catalogSchema);

    return '''You are an AI assistant. Based on the following request, generate a stream of JSON messages that conform to the provided JSON Schemas.

    The output MUST be a series of JSON objects, each enclosed in a markdown code block (or a single block with multiple objects).

    Standard Instructions:
    1. Generate a 'createSurface' message with surfaceId 'main' and catalogId '${catalog.catalogId ?? 'https://a2ui.dev/specification/0.9/standard_catalog_definition.json'}'.
    2. Generate a 'updateComponents' message with surfaceId 'main' containing the requested UI.
    3. Ensure all component children are referenced by ID (using the 'children' or 'child' property with IDs), NOT nested inline as objects.
    4. If the request involves data binding, you may also generate 'updateDataModel' messages.
    5. Among the 'updateComponents' messages in the output, there MUST be one root component with id: 'root'.
    6. Components need to be nested within a root layout container (Column, Row). No need to add an extra container if the root is already a layout container.
    7. There shouldn't be any orphaned components: no components should be generated which don't have a parent, except for the root component.
    8. Do NOT output a list of lists (e.g. [[...]]). Output individual JSON objects separated by newlines.
    9. STRICTLY follow the JSON Schemas. Do NOT add any properties that are not defined in the schema. Ensure ALL required properties are present.
    10. Do NOT invent data bindings or action contexts. Only use them if the prompt explicitly asks for them.
    11. Read the 'description' field of each component in the schema carefully. It contains critical usage instructions (e.g. regarding labels, single child limits, and layout behavior) that you MUST follow.
    12. Do NOT define components inline inside 'child' or 'children'. Always use a string ID referencing a separate component definition.
    13. Do NOT use a 'style' property. Use standard properties like 'alignment', 'distribution', 'usageHint', etc.
    14. Do NOT invent properties that are not in the schema. Check the 'properties' list for each component type.

    Schemas:
    ${A2uiSchemas.serverToClientJson}
    ${A2uiSchemas.commonTypesJson}
    $catalogJson''';
  }

  @override
  void handleMessage(A2uiMessage message, GenUiHost host) {
    switch (message) {
      case UpdateComponents():
        _handleUpdateComponents(host, message.surfaceId, message.components);
      case CreateSurface():
        _handleCreateSurface(host, message.surfaceId, message.catalogId);
      case UpdateDataModel():
        _handleUpdateDataModel(
          host,
          message.surfaceId,
          message.path,
          message.value,
          op: message.op,
        );
      case DeleteSurface():
        host.removeSurface(message.surfaceId);
      case ErrorMessage(:final code, :final message):
        genUiLogger.severe('Received A2UI Error: $code: $message');
      default:
        genUiLogger.warning('Unknown message type for V0.9: $message');
    }
  }

  void _handleUpdateComponents(
    GenUiHost host,
    String surfaceId,
    List<Component> components,
  ) {
    final ValueNotifier<UiDefinition?> notifier = host.getSurfaceNotifier(
      surfaceId,
    );

    UiDefinition uiDefinition =
        notifier.value ?? UiDefinition(surfaceId: surfaceId);
    final Map<String, Component> newComponents = Map.of(
      uiDefinition.components,
    );
    for (final component in components) {
      newComponents[component.id] = component;
    }
    uiDefinition = uiDefinition.copyWith(components: newComponents);
    notifier.value = uiDefinition;

    if (uiDefinition.rootComponentId != null ||
        uiDefinition.components.containsKey('root')) {
      genUiLogger.info('Updating surface $surfaceId');
      host.emitUpdate(SurfaceUpdated(surfaceId, uiDefinition));
    } else {
      genUiLogger.info(
        'Caching components for surface $surfaceId (pre-rendering)',
      );
    }
  }

  void _handleCreateSurface(
    GenUiHost host,
    String surfaceId,
    String catalogId,
  ) {
    host.dataModelForSurface(surfaceId);
    final ValueNotifier<UiDefinition?> notifier = host.getSurfaceNotifier(
      surfaceId,
    );
    final isNew = notifier.value == null;
    final UiDefinition uiDefinition =
        notifier.value ?? UiDefinition(surfaceId: surfaceId);
    final UiDefinition newUiDefinition = uiDefinition.copyWith(
      catalogId: catalogId,
    );
    notifier.value = newUiDefinition;
    genUiLogger.info('Created surface $surfaceId');
    if (isNew) {
      host.emitUpdate(SurfaceAdded(surfaceId, newUiDefinition));
    } else {
      host.emitUpdate(SurfaceUpdated(surfaceId, newUiDefinition));
    }
  }

  void _handleUpdateDataModel(
    GenUiHost host,
    String surfaceId,
    String? path,
    Object value, {
    String op = 'replace',
  }) {
    final String actualPath = path ?? '/';
    genUiLogger.info(
      'Updating data model for surface $surfaceId at path '
      '$actualPath with contents:\n'
      '${const JsonEncoder.withIndent('  ').convert(value)}',
    );
    final DataModel dataModel = host.dataModelForSurface(surfaceId);
    dataModel.update(DataPath(actualPath), value);

    final ValueNotifier<UiDefinition?> notifier = host.getSurfaceNotifier(
      surfaceId,
    );
    final UiDefinition? uiDefinition = notifier.value;
    if (uiDefinition != null &&
        (uiDefinition.rootComponentId != null ||
            uiDefinition.components.containsKey('root'))) {
      host.emitUpdate(SurfaceUpdated(surfaceId, uiDefinition));
    }
  }
}
