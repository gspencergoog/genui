// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart' show Row;
import 'package:flutter/material.dart' show Row;
import 'package:flutter/widgets.dart' show Row;
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../model/catalog_item.dart';
import '../../../model/v0_9/schemas.dart';
import '../../core_widgets/impl/row_impl.dart';

final _schema = S.object(
  properties: {
    'children': A2uiSchemas.componentArrayReference(
      description:
          'Either an explicit list of widget IDs for the children, or a '
          'template with a data binding to the list of children.',
    ),
    'distribution': S.string(
      enumValues: [
        'start',
        'center',
        'end',
        'spaceBetween',
        'spaceAround',
        'spaceEvenly',
      ],
    ),
    'alignment': S.string(
      enumValues: ['start', 'center', 'end', 'stretch', 'baseline'],
    ),
  },
  required: ['children'],
);

/// A catalog item representing a layout widget that displays its children in a
/// horizontal array.
///
/// This widget is analogous to Flutter's [Row] widget. It arranges a list of
/// child components from left to right.
///
/// ## Parameters:
///
/// - `children`: A list of child widget IDs to display in the row.
/// - `distribution`: How the children should be placed along the main axis. Can
///   be `start`, `center`, `end`, `spaceBetween`, `spaceAround`, or
///   `spaceEvenly`. Defaults to `start`.
/// - `alignment`: How the children should be placed along the cross axis. Can
///   be `start`, `center`, `end`, `stretch`, or `baseline`. Defaults to
///   `start`.
final row = CatalogItem(
  name: 'Row',
  dataSchema: _schema,
  widgetBuilder: rowBuilder,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": "Row",
          "children": {
            "explicitList": [
              "text1",
              "text2"
            ]
          }
        },
        {
          "id": "text1",
          "component": "Text",
          "text": {
            "literalString": "First"
          }
        },
        {
          "id": "text2",
          "component": "Text",
          "text": {
            "literalString": "Second"
          }
        }
      ]
    ''',
  ],
);
