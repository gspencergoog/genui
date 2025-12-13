// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart' show ListView;
import 'package:flutter/material.dart' show ListView;
import 'package:flutter/widgets.dart' show ListView;
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../model/catalog_item.dart';
import '../../../model/v0_8/schemas.dart';
import '../../core_widgets/impl/list_impl.dart';

final _schema = S.object(
  properties: {
    'children': A2uiSchemas.componentArrayReference(),
    'direction': S.string(enumValues: ['vertical', 'horizontal']),
    'alignment': S.string(enumValues: ['start', 'center', 'end', 'stretch']),
  },
  required: ['children'],
);

/// A catalog item representing a scrollable list of widgets.
///
/// This widget is analogous to Flutter's [ListView] widget. It can display
/// children in either a vertical or horizontal direction.
///
/// ## Parameters:
///
/// - `children`: A list of child widget IDs to display in the list.
/// - `direction`: The direction of the list. Can be `vertical` or
///   `horizontal`. Defaults to `vertical`.
/// - `alignment`: How the children should be placed along the cross axis.
///   Can be `start`, `center`, `end`, or `stretch`. Defaults to `start`.
final list = CatalogItem(
  name: 'List',
  dataSchema: _schema,
  widgetBuilder: listBuilder,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "List": {
              "children": {
                "explicitList": [
                  "text1",
                  "text2"
                ]
              }
            }
          }
        },
        {
          "id": "text1",
          "component": {
            "Text": {
              "text": {
                "literalString": "First"
              }
            }
          }
        },
        {
          "id": "text2",
          "component": {
            "Text": {
              "text": {
                "literalString": "Second"
              }
            }
          }
        }
      ]
    ''',
  ],
);
