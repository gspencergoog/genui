// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart' show TabBar, TabBarView;
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../model/catalog_item.dart';
import '../../../model/v0_9/schemas.dart';
import '../../core_widgets/impl/tabs_impl.dart';

final _schema = S.object(
  properties: {
    'tabItems': S.list(
      items: S.object(
        properties: {
          'title': A2uiSchemas.stringReference(),
          'child': A2uiSchemas.componentReference(),
        },
        required: ['title', 'child'],
      ),
    ),
  },
  required: ['tabItems'],
);

/// A catalog item representing a Material Design tab layout.
///
/// This widget displays a [TabBar] and a [TabBarView] to allow navigation
/// between different child components. Each tab in `tabItems` has a title and
/// a corresponding child component ID to display when selected.
///
/// ## Parameters:
///
/// - `tabItems`: A list of tabs to display, each with a `title` and a `child`
///   widget ID.
final tabs = CatalogItem(
  name: 'Tabs',
  dataSchema: _schema,
  widgetBuilder: tabsBuilder,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": "Tabs",
          "tabItems": [
            {
              "title": "Overview",
              "child": "text1"
            },
            {
              "title": "Details",
              "child": "text2"
            }
          ]
        },
        {
          "id": "text1",
          "component": "Text",
          "text": "This is a short summary of the item."
        },
        {
          "id": "text2",
          "component": "Text",
          "text": "This is a much longer, more detailed description of the item, providing in-depth information and context. It can span multiple lines and include rich formatting if needed."
        }
      ]
    ''',
  ],
);
