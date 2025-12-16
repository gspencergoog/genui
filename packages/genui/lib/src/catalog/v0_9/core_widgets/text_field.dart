// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../model/catalog_item.dart';
import '../../../model/v0_9/schemas.dart';
import '../../core_widgets/impl/text_field_impl.dart';

final _schema = S.object(
  properties: {
    'label': A2uiSchemas.stringReference(
      description: 'The text label for the input field.',
    ),
    'text': A2uiSchemas.stringReference(
      description: 'The value of the text field.',
    ),
    'usageHint': S.string(
      description: 'The type of input field to display.',
      enumValues: ['date', 'longText', 'number', 'shortText', 'obscured'],
    ),
    'validationRegexp': S.string(
      description:
          'A regular expression used for client-side validation of the input.',
    ),
  },
  required: ['label'],
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
          "component": "TextField",
          "text": "Hello World",
          "label": "Greeting"
        }
      ]
    ''',
    () => '''
      [
        {
          "id": "root",
          "component": "TextField",
          "text": "password123",
          "label": "Password",
          "usageHint": "obscured"
        }
      ]
    ''',
  ],
);
