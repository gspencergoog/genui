// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../model/catalog_item.dart';
import '../../../model/v0_9/schemas.dart';
import '../../core_widgets/impl/icon_impl.dart';

final _schema = S.object(
  properties: {
    'name': A2uiSchemas.stringReference(
      description: 'The name of the icon to display.',
      enumValues: AvailableIcons.allAvailable,
    ),
  },
  required: ['name'],
);

/// A catalog item for an icon.
///
/// ### Parameters:
///
/// - `name`: The name of the icon to display.
final icon = CatalogItem(
  name: 'Icon',
  dataSchema: _schema,
  widgetBuilder: iconBuilder,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": "Icon",
          "name": "add"
        }
      ]
    ''',
  ],
);
