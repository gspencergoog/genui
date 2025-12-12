// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../model/catalog_item.dart';
import '../../../model/v0_8/schemas.dart';
import '../../core_widgets/impl/text_impl.dart';

final _schema = S.object(
  properties: {
    'text': A2uiSchemas.stringReference(description: 'The text to display.'),
    'usageHint': S.string(
      description:
          'A hint for how the text should be styled (e.g., h1, h2, p).',
      enumValues: ['h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'p', 'caption'],
    ),
  },
  required: ['text'],
);

/// A catalog item representing a block of styled text.
///
/// This widget displays text, optionally styled as a heading or caption.
/// It supports Markdown formatting.
final text = CatalogItem(
  name: 'Text',
  dataSchema: _schema,
  widgetBuilder: textBuilder,
  exampleData: [
    () => '''
      [
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
          "id": "heading",
          "component": "Text",
          "text": {
            "literalString": "Welcome"
          },
          "usageHint": "h1"
        }
      ]
    ''',
  ],
);
