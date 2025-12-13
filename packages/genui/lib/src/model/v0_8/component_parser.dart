// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../primitives/simple_items.dart';
import '../component_parser.dart';

/// A [ComponentParser] implementation for A2UI protocol v0.8.
class V08ComponentParser extends ComponentParser {
  /// Creates a new [V08ComponentParser].
  const V08ComponentParser();

  @override
  ({String? widgetType, JsonMap widgetData}) parse(JsonMap data) {
    if (data['component'] is! Map) {
      throw ArgumentError(
        'Component must be a map. Instead got: ${data['component']} '
        '(${data['component']?.runtimeType})',
      );
    }
    final MapEntry<dynamic, dynamic>? entry =
        (data['component'] as Map).entries.firstOrNull;
    if (entry == null) {
      throw ArgumentError('No widget type found in component map');
    }
    final widgetType = entry.key as String;
    return (widgetType: widgetType, widgetData: entry.value as JsonMap);
  }
}
