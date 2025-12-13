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

/// Implementation of the A2UI protocol for version 0.8.
class A2uiProtocolV08 implements A2uiProtocol {
  /// Creates an instance of [A2uiProtocolV08].
  const A2uiProtocolV08();

  @override
  A2uiProtocolVersion get version => A2uiProtocolVersion.v0_8;

  @override
  Stream<A2uiMessage> parsePayload(Object payload) {
    if (payload is JsonMap) {
      // Direct JSON map (single message)
      try {
        return Stream.value(parseJson(payload));
      } on FormatException {
        // Not a known message, ignore.
        return const Stream.empty();
      } catch (e, s) {
        return Stream.error(e, s);
      }
    }
    // V0.8 typically dealt with direct JSON objects in typical connectors,
    // but if we receive a stream of lines (Strings), we can parse them too.
    if (payload is String) {
      // Try to parse as JSON if it's a string
      try {
        final Object? json = jsonDecode(payload);
        if (json is JsonMap) {
          return Stream.value(parseJson(json));
        }
      } catch (_) {
        // Ignore non-JSON strings
      }
    }
    return const Stream.empty();
  }

  @override
  A2uiMessage parseJson(JsonMap json) {
    if (json.containsKey('surfaceUpdate')) {
      return SurfaceUpdate.fromJson(json['surfaceUpdate'] as JsonMap);
    }
    if (json.containsKey('dataModelUpdate')) {
      return DataModelUpdate.fromJson(json['dataModelUpdate'] as JsonMap);
    }
    if (json.containsKey('beginRendering')) {
      return BeginRendering.fromJson(json['beginRendering'] as JsonMap);
    }
    // Shared
    if (json.containsKey('deleteSurface')) {
      return DeleteSurface.fromJson(json['deleteSurface'] as JsonMap);
    }
    if (json.containsKey('error')) {
      return ErrorMessage.fromJson(json['error'] as JsonMap);
    }
    throw FormatException('Unknown A2UI V0.8 message type: $json');
  }

  @override
  List<AiTool> getTools(Catalog catalog, void Function(A2uiMessage) onMessage) {
    return [
      SurfaceUpdateTool(handleMessage: onMessage, catalog: catalog),
      BeginRenderingTool(
        handleMessage: onMessage,
        catalogId: catalog.catalogId,
      ),
      DataModelUpdateTool(handleMessage: onMessage),
      DeleteSurfaceTool(
        handleMessage: onMessage,
        messageFactory: (id) => DeleteSurface(surfaceId: id),
      ),
    ];
  }

  @override
  String? getSystemPreamble(Catalog catalog) => null;

  @override
  void handleMessage(A2uiMessage message, GenUiHost host) {
    switch (message) {
      case SurfaceUpdate():
        _handleUpdateComponents(host, message.surfaceId, message.components);
      case BeginRendering():
        _handleBeginRendering(
          host,
          message.surfaceId,
          message.root,
          message.styles,
          message.catalogId,
        );
      case DataModelUpdate():
        _handleUpdateDataModel(
          host,
          message.surfaceId,
          message.path,
          message.contents,
        );
      case DeleteSurface():
        host.removeSurface(message.surfaceId);
      case ErrorMessage(:final code, :final message):
        genUiLogger.severe('Received A2UI Error: $code: $message');
      default:
        genUiLogger.warning('Unknown message type for V0.8: $message');
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

  void _handleBeginRendering(
    GenUiHost host,
    String surfaceId,
    String root,
    JsonMap? styles,
    String? catalogId,
  ) {
    final ValueNotifier<UiDefinition?> notifier = host.getSurfaceNotifier(
      surfaceId,
    );
    final isNew = notifier.value == null;
    UiDefinition uiDefinition =
        notifier.value ?? UiDefinition(surfaceId: surfaceId);

    uiDefinition = uiDefinition.copyWith(
      rootComponentId: root,
      styles: styles,
      catalogId: catalogId ?? uiDefinition.catalogId,
    );
    notifier.value = uiDefinition;

    genUiLogger.info('Begin rendering surface $surfaceId with root $root');

    if (isNew) {
      host.emitUpdate(SurfaceAdded(surfaceId, uiDefinition));
    } else {
      host.emitUpdate(SurfaceUpdated(surfaceId, uiDefinition));
    }
  }

  void _handleUpdateDataModel(
    GenUiHost host,
    String surfaceId,
    String? path,
    Object value,
  ) {
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
