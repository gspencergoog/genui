// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../model/catalog_item.dart';
import '../../../model/v0_8/schemas.dart';
import '../../core_widgets/impl/button_impl.dart';

final _schema = S.object(
  properties: {
    'child': A2uiSchemas.componentReference(),
    'primary': S.boolean(),
    'action': A2uiSchemas.action(),
  },
  required: ['child'],
);

final button = CatalogItem(
  name: 'Button',
  dataSchema: _schema,
  widgetBuilder: buttonBuilder,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": "Button",
          "child": "text",
          "action": {
            "name": "button_pressed"
          }
        },
        {
          "id": "text",
          "component": "Text",
          "text": {
            "literalString": "Hello World"
          }
        }
      ]
    ''',
    () => '''
      [
        {
          "id": "root",
          "component": "Column",
          "children": {
            "explicitList": ["primaryButton", "secondaryButton"]
          }
        },
        {
          "id": "primaryButton",
          "component": "Button",
          "child": "primaryText",
          "primary": true,
          "action": {
            "name": "primary_pressed"
          }
        },
        {
          "id": "secondaryButton",
          "component": "Button",
          "child": "secondaryText",
          "action": {
            "name": "secondary_pressed"
          }
        },
        {
          "id": "primaryText",
          "component": "Text",
          "text": {
            "literalString": "Primary Button"
          }
        },
        {
          "id": "secondaryText",
          "component": "Text",
          "text": {
            "literalString": "Secondary Button"
          }
        }
      ]
    ''',
  ],
);
