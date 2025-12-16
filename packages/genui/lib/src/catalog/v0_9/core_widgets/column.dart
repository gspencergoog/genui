// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart' show Column;
import 'package:flutter/material.dart' show Column;
import 'package:flutter/widgets.dart' show Column;
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../model/catalog_item.dart';
import '../../../model/v0_9/schemas.dart';
import '../../core_widgets/impl/column_impl.dart';

final _schema = S.object(
  description:
      '''A layout component that arranges its children vertically. To create a grid layout, nest Rows within this Column.''',
  properties: {
    'children': A2uiSchemas.childrenProperty(
      description:
          '''Defines the children. Use an array of strings for a fixed set of children, or a template object to generate children from a data list. Children cannot be defined inline, they must be referred to by ID.''',
    ),
    'distribution': S.string(
      description:
          '''Defines the arrangement of children along the main axis (vertically). Use 'spaceBetween' to push items to the edges (e.g. header at top, footer at bottom), or 'start'/'end'/'center' to pack them together.''',
      enumValues: [
        'start',
        'center',
        'end',
        'spaceBetween',
        'spaceAround',
        'spaceEvenly',
        'stretch',
      ],
    ),
    'alignment': S.string(
      description:
          '''Defines the alignment of children along the cross axis (horizontally). This is similar to the CSS 'align-items' property.''',
      enumValues: ['center', 'end', 'start', 'stretch'],
    ),
  },
  required: ['children'],
);

/// A catalog item representing a layout widget that displays its children in a
/// vertical array.
///
/// This widget is analogous to Flutter's [Column] widget. It arranges a list of
/// child components from top to bottom.
///
/// ## Parameters:
///
/// - `distribution`: How the children should be placed along the main axis. Can
///   be `start`, `center`, `end`, `spaceBetween`, `spaceAround`, or
///   `spaceEvenly`. Defaults to `start`.
/// - `alignment`: How the children should be placed along the cross axis. Can
///   be `start`, `center`, `end`, `stretch`, or `baseline`. Defaults to
///   `start`.
/// - `children`: A list of child widget IDs to display in the column.
final column = CatalogItem(
  name: 'Column',
  dataSchema: _schema,
  widgetBuilder: columnBuilder,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": "Column",
          "children": {
            "explicitList": [
              "advice_text",
              "advice_options",
              "submit_button"
            ]
          }
        },
        {
          "id": "advice_text",
          "component": "Text",
          "text": "What kind of advice are you looking for?"
        },
        {
          "id": "advice_options",
          "component": "Text",
          "text": "Some advice options."
        },
        {
          "id": "submit_button",
          "component": "Button",
          "child": "submit_button_text",
          "action": {
            "name": "submit"
          }
        },
        {
          "id": "submit_button_text",
          "component": "Text",
          "text": "Submit"
        }
      ]
    ''',
  ],
);
