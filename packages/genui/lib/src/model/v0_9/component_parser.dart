// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../primitives/simple_items.dart';
import '../component_parser.dart';

/// A [ComponentParser] implementation for A2UI protocol v0.9.
class V09ComponentParser extends ComponentParser {
  /// Creates a new [V09ComponentParser].
  const V09ComponentParser();

  @override
  ({String? widgetType, JsonMap widgetData}) parse(JsonMap data) {
    String? widgetType;
    var widgetData = data;
    final Object? componentEntry = data['component'];

    // In V0.9, the component property is a map where the key is the component
    // name and the value is an object containing the component's properties.
    if (componentEntry is Map && componentEntry.isNotEmpty) {
      widgetType = componentEntry.keys.first as String;
      final Map<String, Object?> innerData =
          componentEntry[widgetType] as Map<String, Object?>? ?? {};
      // We merge the inner properties to the top level for the widget builder,
      // preserving the ID from the outer object if it exists (though usually
      // the ID is not in the component map itself in V0.9 schemas, but the
      // wrapping object has it).
      widgetData = {...innerData, if (data.containsKey('id')) 'id': data['id']};
    } else if (componentEntry is String) {
      // Fallback or potentially mixed usage, though strictly V0.9 uses Map.
      widgetType = componentEntry;
    }

    return (widgetType: widgetType, widgetData: widgetData);
  }
}
