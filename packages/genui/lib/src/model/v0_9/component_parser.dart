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
    final Object? componentEntry = data['component'];

    if (componentEntry is String) {
      return (widgetType: componentEntry, widgetData: data);
    } else {
      throw ArgumentError(
        'Invalid component format in v0.9: "component" property must be a '
        'String. Got: $componentEntry (${componentEntry?.runtimeType}) in '
        'data: $data',
      );
    }
  }
}
