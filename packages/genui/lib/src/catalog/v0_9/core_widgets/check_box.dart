// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart' show Text;
import 'package:flutter/material.dart' show Text;
import 'package:flutter/widgets.dart' show Text;
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../model/catalog_item.dart';
import '../../../model/v0_9/schemas.dart';
import '../../core_widgets/impl/check_box_impl.dart';

final _schema = S.object(
  properties: {
    'label': A2uiSchemas.stringReference(
      description: 'The text to display next to the checkbox.',
    ),
    'value': A2uiSchemas.booleanReference(
      description:
          '''The current state of the checkbox (true for checked, false for unchecked).''',
    ),
  },
  required: ['label', 'value'],
);

/// A catalog item representing a Material Design checkbox with a label.
///
/// This widget displays a checkbox a [Text] label. The checkbox's state
/// is bidirectionally bound to the data model path specified in the `value`
/// parameter.
///
/// ## Parameters:
///
/// - `label`: The text to display next to the checkbox.
/// - `value`: The boolean value of the checkbox.
final checkBox = CatalogItem(
  name: 'CheckBox',
  dataSchema: _schema,
  widgetBuilder: checkBoxBuilder,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": "CheckBox",
          "label": "Check me",
          "value": {
            "path": "/myValue"
          }
        }
      ]
    ''',
  ],
);
