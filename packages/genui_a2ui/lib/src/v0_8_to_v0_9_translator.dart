// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genui/genui.dart';
import 'package:logging/logging.dart';

final _log = Logger('A2ui08To09Translator');

/// Translates A2UI v0.8 messages to v0.9 format.
class A2ui08To09Translator {
  /// Translates a stream of v0.8 JSON maps into a stream of v0.9 [A2uiMessage]s.
  Stream<A2uiMessage> translate(Stream<Map<String, Object?>> v08Stream) async* {
    await for (final message in v08Stream) {
      yield* translateOne(message);
    }
  }

  /// Translates a single v0.8 JSON map into v0.9 [A2uiMessage]s.
  Stream<A2uiMessage> translateOne(Map<String, Object?> message) async* {
    if (message.containsKey('beginRendering')) {
      yield* _translateBeginRendering(
        message['beginRendering'] as Map<String, Object?>,
      );
    } else if (message.containsKey('surfaceUpdate')) {
      yield* _translateSurfaceUpdate(
        message['surfaceUpdate'] as Map<String, Object?>,
      );
    } else if (message.containsKey('dataModelUpdate')) {
      yield* _translateDataModelUpdate(
        message['dataModelUpdate'] as Map<String, Object?>,
      );
    } else if (message.containsKey('surfaceDeletion')) {
      yield* _translateSurfaceDeletion(
        message['surfaceDeletion'] as Map<String, Object?>,
      );
    }
  }

  Stream<A2uiMessage> _translateBeginRendering(
    Map<String, Object?> content,
  ) async* {
    // v0.8: { surfaceId, styles, ... }
    // v0.9: { surfaceId, catalogId, theme, rootComponentId: 'root' }
    final String surfaceId = content['surfaceId'] as String? ?? 'default';
    final styles = content['styles'] as Map<String, Object?>?;

    yield CreateSurface(
      surfaceId: surfaceId,
      catalogId:
          'a2ui.org:standard_catalog_0_8_0', // Default for v0.8 translation
      theme: styles,
      attachDataModel: true,
    );
  }

  Stream<A2uiMessage> _translateSurfaceUpdate(
    Map<String, Object?> content,
  ) async* {
    // v0.8: { surfaceId, components: [ { id, component: { Type: { props } } } ] }
    // v0.9: { surfaceId, components: [ { id, type: Type, ...props } ] }
    final String surfaceId = content['surfaceId'] as String? ?? 'default';
    final List<Object?> componentsV08 =
        content['components'] as List<Object?>? ?? [];

    final List<Component> componentsV09 = [];

    for (final compObj in componentsV08) {
      if (compObj is! Map<String, Object?>) continue;

      final id = compObj['id'] as String;
      final componentWrapper = compObj['component'] as Map<String, Object?>?;

      if (componentWrapper == null || componentWrapper.isEmpty) {
        _log.warning(
          'Component $id has no "component" wrapper in v0.8 message.',
        );
        continue;
      }

      final String type = componentWrapper.keys.first;
      final Map<String, Object?> props =
          componentWrapper[type] as Map<String, Object?>? ?? {};

      // Property Translations
      final Map<String, Object?> newProps = Map.of(props);
      newProps['type'] = type;

      // Rename known props
      if (newProps.containsKey('usageHint')) {
        newProps['variant'] = newProps.remove('usageHint');
      }
      if (newProps.containsKey('text') &&
          (type == 'TextField' || type == 'Text')) {
        // Only rename if it's semantically a value. For 'Text' widget, 'text' property remains 'text' in v0.9?
        // Checking standard catalog...
        // In v0.9 'Text' widget has 'text' property.
        // 'TextField' has 'label', 'value'.
        // v0.8 'TextField' had 'label' and 'text'? Or just 'label'?
        // Assuming 'text' -> 'value' for input fields if present.
        if (type == 'TextField') {
          if (newProps.containsKey('text')) {
            newProps['value'] = newProps.remove('text');
          }
        }
      }

      // Convert Data Binding if necessary (schema dependent)

      componentsV09.add(Component(id: id, componentProperties: newProps));
    }

    yield UpdateComponents(surfaceId: surfaceId, components: componentsV09);
  }

  Stream<A2uiMessage> _translateDataModelUpdate(
    Map<String, Object?> content,
  ) async* {
    // v0.8: { surfaceId, contents: [ { key: 'path', valueString: 'val' } ] }
    // v0.9: { surfaceId, value: { 'path': 'val' } }
    final String surfaceId = content['surfaceId'] as String? ?? 'default';
    final List<Object?> contents = content['contents'] as List<Object?>? ?? [];

    final Map<String, Object?> updateMap = {};

    for (final item in contents) {
      if (item is Map<String, Object?>) {
        final key = item['key'] as String?;
        // v0.8 had typed value fields e.g., valueString, valueInt
        final Object? value =
            item['valueString'] ??
            item['valueInt'] ??
            item['valueBool'] ??
            item['valueDouble'];

        if (key != null) {
          updateMap[key] = value;
        }
      }
    }

    yield UpdateDataModel(surfaceId: surfaceId, value: updateMap);
  }

  Stream<A2uiMessage> _translateSurfaceDeletion(
    Map<String, Object?> content,
  ) async* {
    final String surfaceId = content['surfaceId'] as String? ?? 'default';
    yield DeleteSurface(surfaceId: surfaceId);
  }
}
