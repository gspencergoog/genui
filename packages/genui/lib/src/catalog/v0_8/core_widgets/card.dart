// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../model/catalog_item.dart';
import '../../../model/v0_8/schemas.dart';
import '../../core_widgets/impl/card_impl.dart';

final _schema = S.object(
  properties: {'child': A2uiSchemas.componentReference()},
  required: ['child'],
);

/// A catalog item representing a Material Design card.
///
/// This widget displays a card, which is a container for a single `child`
/// widget. Cards often have rounded corners and a shadow, and are used to group
/// related content.
///
/// ## Parameters:
///
/// - `child`: The ID of a child widget to display inside the card.
final card = CatalogItem(
  name: 'Card',
  dataSchema: _schema,
  widgetBuilder: cardBuilder,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
             "Card": {
               "child": "text"
             }
          }
        },
        {
          "id": "text",
          "component": {
            "Text": {
              "text": {
                "literalString": "This is a card."
              }
            }
          }
        }
      ]
    ''',
  ],
);
