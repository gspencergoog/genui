// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../model/catalog_item.dart';
import '../../core_widgets/impl/divider_impl.dart';

final _schema = S.object(
  properties: {
    'axis': S.string(enumValues: ['horizontal', 'vertical']),
  },
);

/// A catalog item representing a Material Design divider.
///
/// This widget displays a thin line to separate content, either horizontally
/// or vertically.
///
/// ## Parameters:
///
/// - `axis`: The direction of the divider. Can be `horizontal` or `vertical`.
///   Defaults to `horizontal`.
final divider = CatalogItem(
  name: 'Divider',
  dataSchema: _schema,
  widgetBuilder: dividerBuilder,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "Divider": {}
          }
        }
      ]
    ''',
  ],
);
