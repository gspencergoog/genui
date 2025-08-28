// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';

import '../primitives/simple_items.dart';
import 'ui_event_manager.dart';

/// A callback that builds a child widget for a catalog item.
typedef ChildBuilderCallback = Widget Function(String id);

/// A store for widget values, organized by surface ID.
///
/// This class is used to maintain the state of widgets on different surfaces.
class WidgetValueStore {
  final Map<String, JsonMap> _values = {};

  /// Returns the value store for the given [surfaceId].
  ///
  /// If a store for the given ID does not exist, a new one is created.
  JsonMap forSurface(String surfaceId) {
    return _values.putIfAbsent(surfaceId, () => {});
  }

  /// Deletes the value store for the given [surfaceId].
  void delete(String surfaceId) {
    _values.remove(surfaceId);
  }
}

/// A callback that builds a widget for a catalog item.
typedef CatalogWidgetBuilder = Widget Function({
  /// The actual deserialized JSON data for this widget. The format of this
  /// data will exactly match [CatalogItem.dataSchema].
  required Object data,

  /// The ID of this widget.
  required String id,

  /// A function used to build a child based on the given ID.
  required ChildBuilderCallback buildChild,

  /// A function used to dispatch an event.
  required DispatchEventCallback dispatchEvent,

  required BuildContext context,

  /// The current values of all widgets on the surface.
  required JsonMap values,
});

/// Defines a UI component, its schema, and how to build its widget.
///
/// Each [CatalogItem] represents a single type of widget that can be used by
/// the generative AI model to construct a UI.
class CatalogItem {
  /// Creates a new [CatalogItem].
  const CatalogItem({
    required this.name,
    required this.dataSchema,
    required this.widgetBuilder,
    this.exampleData,
  });

  /// The widget type name used in JSON, e.g., 'TextChatMessage'.
  final String name;

  /// The schema definition for this widget's data.
  final Schema dataSchema;

  /// The builder for this widget.
  final CatalogWidgetBuilder widgetBuilder;

  /// Example data for this widget, for testing purposes.
  final Map<String, Object?>? exampleData;
}