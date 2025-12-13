// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../model/catalog_item.dart';
import '../../../model/v0_8/schemas.dart';
import '../../core_widgets/impl/text_field_impl.dart';

final _schema = S.object(
  properties: {
    'text': A2uiSchemas.stringReference(),
    'label': A2uiSchemas.stringReference(),
    'usageHint': S.string(),
  },
  required: ['text'],
);

final textField = CatalogItem(
  name: 'TextField',
  dataSchema: _schema,
  widgetBuilder: textFieldBuilder,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "TextField": {
              "text": {
                "literalString": "Hello World"
              },
              "label": {
                "literalString": "Greeting"
              }
            }
          }
        }
      ]
    ''',
    () => '''
      [
        {
          "id": "root",
          "component": {
            "TextField": {
              "text": {
                "literalString": "password123"
              },
              "label": {
                "literalString": "Password"
              },
              "usageHint": "obscured"
            }
          }
        }
      ]
    ''',
  ],
);
