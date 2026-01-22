// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport '../../core/genui_surface.dart';
library;

import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';
import '../../primitives/simple_items.dart';

final _schema = S.object(
  properties: {
    'trigger': S.string(description: 'The widget that opens the modal.'),
    'content': S.string(description: 'The widget to display in the modal.'),
  },
  required: ['trigger', 'content'],
);

extension type _ModalData.fromMap(JsonMap _json) {
  factory _ModalData({required String trigger, required String content}) =>
      _ModalData.fromMap({'trigger': trigger, 'content': content});

  String get trigger => _json['trigger'] as String;
  String get content => _json['content'] as String;
}

/// A catalog item representing a modal bottom sheet.
///
/// This component doesn't render the modal content directly. Instead, it
/// renders the `trigger` widget. The `trigger` is expected to
/// trigger an action (e.g., on button press) that causes the `content` to
/// be displayed within a modal bottom sheet by the [GenUiSurface].
///
/// ## Parameters:
///
/// - `trigger`: The ID of the widget that opens the modal.
/// - `content`: The ID of the widget to display in the modal.
final modal = CatalogItem(
  name: 'Modal',
  dataSchema: _schema,
  widgetBuilder: (itemContext) {
    final modalData = _ModalData.fromMap(itemContext.data as JsonMap);
    return itemContext.buildChild(modalData.trigger);
  },
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "type": "Modal",
          "trigger": "button",
          "content": "text"
        },
        {
          "id": "button",
          "type": "Button",
          "child": "button_text",
          "action": {
            "name": "showModal",
            "context": {
              "modalId": "root"
            }
          }
        },
        {
          "id": "button_text",
          "type": "Text",
          "text": "Open Modal"
        },
        {
          "id": "text",
          "type": "Text",
          "text": "This is a modal."
        }
      ]
    ''',
  ],
);
