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
          'The ID of a child widget. This should always be set, e.g. to the ID '
          'of a `Text` widget.',
    ),
    'action': A2uiSchemas.action(),
    'primary': S.boolean(
      description: 'Whether the button invokes a primary action.',
    ),
  },
  required: ['child', 'action'],
);

/// A catalog item representing a Material Design elevated button.
///
/// This widget displays an interactive button. When pressed, it dispatches
/// the specified `action` event. The button's appearance can be styled as
/// a primary action.
///
/// ## Parameters:
///
/// - `child`: The ID of a child widget to display inside the button.
/// - `action`: The action to perform when the button is pressed.
/// - `primary`: Whether the button invokes a primary action (defaults to
///   false).
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
