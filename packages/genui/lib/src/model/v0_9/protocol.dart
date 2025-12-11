// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/genui_host.dart';
import '../../core/ui_tools.dart';
import '../../model/data_model.dart';
import '../../model/ui_models.dart';
import '../../primitives/logging.dart';
import '../../primitives/simple_items.dart';
import '../a2ui_message.dart';
import '../a2ui_protocol.dart';
import '../catalog.dart';
import '../tools.dart';
import 'messages.dart';

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
    return [
      UpdateComponentsTool(handleMessage: onMessage, catalog: catalog),
      CreateSurfaceTool(handleMessage: onMessage),
      DeleteSurfaceTool(
        handleMessage: onMessage,
        messageFactory: (id) => DeleteSurface(surfaceId: id),
      ),
    ];
  }

  @override
  String? getSystemPreamble(Catalog catalog) {
    final String definition = const JsonEncoder.withIndent(
      '  ',
    ).convert(catalog.definition.toJson());
    return 'You have access to the following UI components:\n'
        '$definition\n\n'
        'You must output your response as a stream of JSON objects, one per '
        'line (JSONL). Each line can be either a plain text response or a '
        'structured A2UI message (e.g., createSurface, updateComponents). '
        'Do not wrap the JSON objects in a list or any other structure. '
        'Just output one JSON object per line.';
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
