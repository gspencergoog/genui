// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/genui_host.dart';
import '../core/ui_tools.dart';
import '../model/data_model.dart';
import '../model/ui_models.dart';
import '../primitives/logging.dart';
import '../primitives/simple_items.dart';
import 'a2ui_message.dart';
import 'catalog.dart';
import 'tools.dart';

/// The versions of the A2UI protocol.
enum A2uiProtocolVersion {
  /// Version 0.8.
  v0_8,

  /// Version 0.9.
  v0_9;

  /// Returns the string representation of the version (e.g. "0.8").
  String get label => switch (this) {
    A2uiProtocolVersion.v0_8 => '0.8',
    A2uiProtocolVersion.v0_9 => '0.9',
  };
}

/// An abstract interface for the A2UI protocol.
///
/// This allows for supporting multiple versions of the A2UI spec (e.g. 0.8,
/// 0.9) and potentially non-JSON protocols in the future.
abstract interface class A2uiProtocol {
  /// Creates an instance of [A2uiProtocol] from an [A2uiProtocolVersion].
  factory A2uiProtocol.fromVersion(A2uiProtocolVersion version) {
    switch (version) {
      case A2uiProtocolVersion.v0_8:
        return const A2uiProtocolV08();
      case A2uiProtocolVersion.v0_9:
        return const A2uiProtocolV09();
    }
  }

  /// The version of the A2UI protocol.
  A2uiProtocolVersion get version;

  /// Parses the payload into a stream of [A2uiMessage]s.
  ///
  /// The [payload] can be a JSON Map, a String (for text-based protocols or
  /// scripts), or other formats.
  Stream<A2uiMessage> parsePayload(Object payload);

  /// Parses a single JSON map into an [A2uiMessage].
  ///
  /// This is synchronous and expects a well-formed JSON object representing a
  /// single message.
  A2uiMessage parseJson(JsonMap json);

  /// Returns the tools required by this protocol version for inference.
  List<AiTool> getTools(Catalog catalog, void Function(A2uiMessage) onMessage);

  /// Returns the system preamble (instructions/schema) for this protocol.
  String? getSystemPreamble(Catalog catalog);

  /// Handles the message by applying it to the host.
  void handleMessage(A2uiMessage message, GenUiHost host);
}

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
      DeleteSurfaceTool(handleMessage: onMessage),
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
      DeleteSurfaceTool(handleMessage: onMessage),
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
