// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart' show Slider;
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../model/catalog_item.dart';
import '../../../model/v0_9/schemas.dart';
import '../../core_widgets/impl/slider_impl.dart';

final _schema = S.object(
  properties: {
    'value': A2uiSchemas.numberReference(),
    'min': A2uiSchemas.numberReference(),
    'max': A2uiSchemas.numberReference(),
  },
  required: ['value'],
);

/// A catalog item representing a Material Design slider.
///
/// This widget allows the user to select a value from a range by sliding a
/// thumb along a track. The `value` is bidirectionally bound to the data model.
/// This is analogous to Flutter's [Slider] widget.
///
/// ## Parameters:
///
/// - `value`: The current value of the slider.
/// - `min`: The minimum value of the slider. Defaults to 0.0.
/// - `max`: The maximum value of the slider. Defaults to 1.0.
final slider = CatalogItem(
  name: 'Slider',
  dataSchema: _schema,
  widgetBuilder: sliderBuilder,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": "Slider",
          "min": {"literalNumber": 0},
          "max": {"literalNumber": 10},
          "value": {
            "path": "/myValue",
            "literalNumber": 5
          }
        }
      ]
    ''',
  ],
);
