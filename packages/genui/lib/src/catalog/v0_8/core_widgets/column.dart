// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart' show Column;
import 'package:flutter/material.dart' show Column;
import 'package:flutter/widgets.dart' show Column;
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../model/catalog_item.dart';
import '../../../model/v0_8/schemas.dart';
import '../../core_widgets/impl/column_impl.dart';

final _schema = S.object(
  properties: {
    'distribution': S.string(
      description: 'How children are aligned on the main axis. ',
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
      description: 'How children are aligned on the cross axis. ',
      enumValues: ['start', 'center', 'end', 'stretch', 'baseline'],
    ),
    'children': Schemas.componentArrayReference(
      description:
          'Either an explicit list of widget IDs for the children, or a '
          'template with a data binding to the list of children.',
    ),
  },
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
          "text": {
            "literalString": "What kind of advice are you looking for?"
          }
        },
        {
          "id": "advice_options",
          "component": "Text",
          "text": {
            "literalString": "Some advice options."
          }
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
          "text": {
            "literalString": "Submit"
          }
        }
      ]
    ''',
  ],
);
