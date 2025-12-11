// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../model/catalog_item.dart';
import '../../../model/v0_8/schemas.dart';
import '../../core_widgets/impl/image_impl.dart';

Schema _schema({required bool enableUsageHint}) {
  final Map<String, Schema> properties = {
    'url': Schemas.stringReference(
      description:
          'Asset path (e.g. assets/...) or network URL (e.g. https://...)',
    ),
    'fit': S.string(
      description: 'How the image should be inscribed into the box.',
      enumValues: BoxFit.values.map((e) => e.name).toList(),
    ),
  };
  if (enableUsageHint) {
    properties['usageHint'] = S.string(
      description: '''A hint for the image size and style. One of:
      - icon: Small square icon.
      - avatar: Circular avatar image.
      - smallFeature: Small feature image.
      - mediumFeature: Medium feature image.
      - largeFeature: Large feature image.
      - header: Full-width, full bleed, header image.''',
      enumValues: [
        'icon',
        'avatar',
        'smallFeature',
        'mediumFeature',
        'largeFeature',
        'header',
      ],
    );
  }
  return S.object(properties: properties);
}

/// Returns a catalog item representing a widget that displays an image.
CatalogItem _imageCatalogItem({
  /// When set to `true`, the `usageHint` parameter will be included in the
  /// schema for the image widget. This allows the AI model to provide hints
  /// for the image's size and style, such as 'icon', 'avatar', or 'header'.
  /// When set to `false`, the `usageHint` parameter is omitted from the schema,
  /// preventing the model from using it.
  required bool enableUsageHint,
}) {
  return CatalogItem(
    name: 'Image',
    dataSchema: _schema(enableUsageHint: enableUsageHint),
    exampleData: [
      () => '''
      [
        {
          "id": "root",
          "component": "Image",
          "url": {
            "literalString": "https://storage.googleapis.com/cms-storage-bucket/lockup_flutter_horizontal.c823e53b3a1a7b0d36a9.png"
          },
          "usageHint": "mediumFeature"
        }
      ]
    ''',
    ],
    widgetBuilder: imageBuilder,
  );
}

/// A catalog item representing a widget that displays an image.
///
/// The image source is specified by the `url` parameter, which can be a network
/// URL (e.g., `https://...`) or a local asset path (e.g., `assets/...`).
///
/// ## Parameters:
///
/// - `url`: The URL of the image to display. Can be a network URL or a local
///   asset path.
/// - `fit`: How the image should be inscribed into the box. See [BoxFit] for
///   possible values.
/// - `usageHint`: A usage hint for the image size and style. One of 'icon',
///   'avatar', 'smallFeature', 'mediumFeature', 'largeFeature', 'header'.
final CatalogItem image = _imageCatalogItem(enableUsageHint: true);

/// A variant of the image catalog item which does not expose a usageHint to let
/// the LLM determine the size. Instead, it is always medium sized.
///
/// See [image] for full documentation.
final CatalogItem imageFixedSize = _imageCatalogItem(enableUsageHint: false);
