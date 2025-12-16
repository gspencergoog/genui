// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../model/catalog_item.dart';
import '../../../model/v0_9/schemas.dart';
import '../../core_widgets/impl/choice_picker_impl.dart';

final _schema = S.object(
  description:
      'A component that allows selecting one or more options from a list.',
  properties: {
    'label': A2uiSchemas.stringReference(
      description: 'The label for the group of options.',
    ),
    'usageHint': S.string(
      description:
          'A hint for how the choice picker should be displayed and behave.',
      enumValues: ['multipleSelection', 'mutuallyExclusive'],
    ),
    'options': S.list(
      description: 'The list of available options to choose from.',
      items: S.object(
        properties: {
          'label': A2uiSchemas.stringReference(
            description: 'The text to display for this option.',
          ),
          'value': S.string(
            description: 'The stable value associated with this option.',
          ),
        },
        required: ['label', 'value'],
        additionalProperties: false,
      ),
    ),
    'value': A2uiSchemas.stringArrayReference(
      description:
          '''The list of currently selected values. This should be bound to a string array in the data model.''',
    ),
  },
  required: ['options', 'value', 'usageHint'],
);

/// A catalog item representing a choice picker widget.
///
/// This widget displays a list of options, each with a checkbox or radio
/// button.
///
/// The `value` parameter, which should be a data model path, is updated to
/// reflect the list of *values* of the currently selected options.
///
/// ## Parameters:
///
/// - `value`: A list of the values of the selected options.
/// - `options`: A list of options to display, each with a `label` and a
///   `value`.
/// - `usageHint`: Hints at how the picker should behave. 'mutuallyExclusive'
///   implies single selection (radio buttons), while 'multipleSelection'
///   implies multiple selection (checkboxes). Defaults to 'multipleSelection'.
final choicePicker = CatalogItem(
  name: 'ChoicePicker',
  dataSchema: _schema,
  widgetBuilder: choicePickerBuilder,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": "Column",
          "children": {
            "explicitList": [
              "heading1",
              "singleChoice",
              "heading2",
              "multiChoice"
            ]
          }
        },
        {
          "id": "heading1",
          "component": "Text",
          "text": "Single Selection (mutuallyExclusive)"
        },
        {
          "id": "singleChoice",
          "component": "ChoicePicker",
          "value": {
            "path": "/singleSelection"
          },
          "usageHint": "mutuallyExclusive",
          "options": [
              {
                "label": "Option A",
                "value": "A"
              },
              {
                "label": "Option B",
                "value": "B"
              }
            ]
        },
        {
          "id": "heading2",
          "component": "Text",
          "text": "Multiple Selections"
        },
        {
          "id": "multiChoice",
          "component": "ChoicePicker",
          "value": {
            "path": "/multiSelection"
          },
          "options": [
              {
                "label": "Option X",
                "value": "X"
              },
              {
                "label": "Option Y",
                "value": "Y"
              },
              {
                "label": "Option Z",
                "value": "Z"
              }
            ]
        }
      ]
    ''',
  ],
);
