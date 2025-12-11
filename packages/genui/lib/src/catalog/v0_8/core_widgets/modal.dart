// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport '../../../core/genui_surface.dart';
library;

import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../model/catalog_item.dart';
import '../../../model/v0_8/schemas.dart';
import '../../core_widgets/impl/modal_impl.dart';

final _schema = S.object(
  properties: {
    'entryPointChild': Schemas.componentReference(
      description: 'The widget that opens the modal.',
    ),
    'contentChild': Schemas.componentReference(
      description: 'The widget to display in the modal.',
    ),
  },
  required: ['entryPointChild', 'contentChild'],
);

/// A catalog item representing a modal bottom sheet.
///
/// This component doesn't render the modal content directly. Instead, it
/// renders the `entryPointChild` widget. The `entryPointChild` is expected to
/// trigger an action (e.g., on button press) that causes the `contentChild` to
/// be displayed within a modal bottom sheet by the [GenUiSurface].
///
/// ## Parameters:
///
/// - `entryPointChild`: The ID of the widget that opens the modal.
/// - `contentChild`: The ID of the widget to display in the modal.
final modal = CatalogItem(
  name: 'Modal',
  dataSchema: _schema,
  widgetBuilder: modalBuilder,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": "Modal",
          "entryPointChild": "button",
          "contentChild": "text"
        },
        {
          "id": "button",
          "component": "Button",
          "child": "button_text",
          "action": {
            "name": "showModal",
            "context": {
              "modalId": {
                "literalString": "root"
              }
            }
          }
        },
        {
          "id": "button_text",
          "component": "Text",
          "text": {
            "literalString": "Open Modal"
          }
        },
        {
          "id": "text",
          "component": "Text",
          "text": {
            "literalString": "This is a modal."
          }
        }
      ]
    ''',
  ],
);
