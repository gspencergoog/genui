// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../primitives/simple_items.dart';

/// Strategy for parsing component data from a JSON map.
abstract class ComponentParser {
  /// Constant constructor for subclasses.
  const ComponentParser();

  /// Parses the [data] map to extract the widget type and properties.
  ({String? widgetType, JsonMap widgetData}) parse(JsonMap data);
}
