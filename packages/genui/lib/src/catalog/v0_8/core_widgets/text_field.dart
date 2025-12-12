// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart' show TextField;
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../model/catalog_item.dart';
import '../../../model/v0_8/schemas.dart';
import '../../core_widgets/impl/text_field_impl.dart';

import '../context_resolution.dart' as v0_8;

final _schema = S.object(
  properties: {
    'text': A2uiSchemas.stringReference(
      description: 'The initial value of the text field.',
    ),
    'label': A2uiSchemas.stringReference(),
    'usageHint': S.string(
      enumValues: ['shortText', 'longText', 'number', 'date', 'obscured'],
    ),
    'validationRegexp': S.string(),
    'onSubmittedAction': A2uiSchemas.action(),
  },
);

/// A catalog item representing a Material Design text field.
///
/// This widget allows the user to enter and edit text. The `text` parameter
/// bidirectionally binds the field's content to the data model. This is
/// analogous to Flutter's [TextField] widget.
///
/// ## Parameters:
///
/// - `text`: The initial value of the text field.
/// - `label`: The text to display as the label for the text field.
/// - `usageHint`: The type of text field. Can be `shortText`, `longText`,
///   `number`, `date`, or `obscured`.
/// - `validationRegexp`: A regular expression to validate the input.
/// - `onSubmittedAction`: The action to perform when the user submits the
///   text field.
final textField = CatalogItem(
  name: 'TextField',
  dataSchema: _schema,
  widgetBuilder: (context) =>
      textFieldBuilder(context, resolveContext: v0_8.resolveContext),
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": "TextField",
          "text": {
            "literalString": "Hello World"
          },
          "label": {
            "literalString": "Greeting"
          }
        }
      ]
    ''',
    () => '''
      [
        {
          "id": "root",
          "component": "TextField",
          "text": {
            "literalString": "password123"
          },
          "label": {
            "literalString": "Password"
          },
          "usageHint": "obscured"
        }
      ]
    ''',
  ],
);
