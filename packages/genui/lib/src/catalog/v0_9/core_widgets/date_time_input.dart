// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../model/catalog_item.dart';
import '../../../model/v0_9/schemas.dart';
import '../../core_widgets/impl/date_time_input_impl.dart';

final _schema = S.object(
  properties: {
    'value': A2uiSchemas.stringReference(
      description:
          'The selected date and/or time value in ISO 8601 format. If not yet set, initialize with an empty string.',
    ),
    'enableDate': S.boolean(
      description: 'If true, allows the user to select a date.',
    ),
    'enableTime': S.boolean(
      description: 'If true, allows the user to select a time.',
    ),
    'outputFormat': S.string(
      description:
          '''The desired format for the output string after a date or time is selected.''',
    ),
    'label': A2uiSchemas.stringReference(
      description: 'The text label for the input field.',
    ),
  },
  required: ['value'],
);

/// A catalog item representing a Material Design date and/or time input field.
///
/// This widget displays a field that, when tapped, opens the native date and/or
/// time pickers. The selected value is stored as a string in the data model
/// path specified in the `value` parameter.
///
/// ## Parameters:
///
/// - `value`: The selected date and/or time, as a string.
/// - `enableDate`: Whether to allow the user to select a date. Defaults to
///   `true`.
/// - `enableTime`: Whether to allow the user to select a time. Defaults to
///   `true`.
/// - `outputFormat`: The format to use for the output string.
final dateTimeInput = CatalogItem(
  name: 'DateTimeInput',
  dataSchema: _schema,
  widgetBuilder: dateTimeInputBuilder,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": "DateTimeInput",
          "value": {
            "path": "/myDateTime"
          }
        }
      ]
    ''',
  ],
);
