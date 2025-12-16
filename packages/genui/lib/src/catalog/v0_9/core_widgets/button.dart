// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../model/catalog_item.dart';
import '../../../model/v0_9/schemas.dart';
import '../../core_widgets/impl/button_impl.dart';

final _schema = S.object(
  properties: {
    'child': A2uiSchemas.componentReference(
      description:
          '''The ID of the child component. Use a 'Text' component for a labeled button. Only use an 'Icon' if the requirements explicitly ask for an icon-only button. Do NOT define the child component inline.''',
    ),
    'primary': S.boolean(
      description:
          'Indicates if this button should be styled as the primary action.',
    ),
    'action': A2uiSchemas.action(
      description:
          '''The client-side action to be dispatched when the button is clicked. It includes the action's name and an optional context payload.''',
    ),
  },
  required: ['component', 'child', 'action'],
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
          "text": "Hello World"
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
          "text": "Primary Button"
        },
        {
          "id": "secondaryText",
          "component": "Text",
          "text": "Secondary Button"
          }
        }
      ]
    ''',
  ],
);
