// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../model/catalog_item.dart';
import '../../../model/v0_8/schemas.dart';
import '../../core_widgets/impl/choice_picker_impl.dart';

final _schema = S.object(
  properties: {
    'value': A2uiSchemas.stringArrayReference(),
    'options': A2uiSchemas.objectArrayReference(),
    'usageHint': S.string(
      description: 'Hint for how the choice picker should be displayed.',
      enumValues: ['multipleSelection', 'mutuallyExclusive'],
    ),
  },
  required: ['value', 'options'],
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
          "component": {
            "Column": {
              "children": {
                "explicitList": [
                  "heading1",
                  "singleChoice",
                  "heading2",
                  "multiChoice"
                ]
              }
            }
          }
        },
        {
          "id": "heading1",
          "component": {
            "Text": {
              "text": {
                "literalString": "Single Selection (mutuallyExclusive)"
              }
            }
          }
        },
        {
          "id": "singleChoice",
          "component": {
            "ChoicePicker": {
              "value": {
                "path": "/singleSelection"
              },
              "usageHint": "mutuallyExclusive",
              "options": {
                "literalArray": [
                  {
                    "label": {
                      "literalString": "Option A"
                    },
                    "value": "A"
                  },
                  {
                    "label": {
                      "literalString": "Option B"
                    },
                    "value": "B"
                  }
                ]
              }
            }
          }
        },
        {
          "id": "heading2",
          "component": {
            "Text": {
              "text": {
                "literalString": "Multiple Selections"
              }
            }
          }
        },
        {
          "id": "multiChoice",
          "component": {
            "ChoicePicker": {
              "value": {
                "path": "/multiSelection"
              },
              "options": {
                "literalArray": [
                  {
                    "label": {
                      "literalString": "Option X"
                    },
                    "value": "X"
                  },
                  {
                    "label": {
                      "literalString": "Option Y"
                    },
                    "value": "Y"
                  },
                  {
                    "label": {
                      "literalString": "Option Z"
                    },
                    "value": "Z"
                  }
                ]
              }
            }
          }
        }
      ]
    ''',
  ],
);
