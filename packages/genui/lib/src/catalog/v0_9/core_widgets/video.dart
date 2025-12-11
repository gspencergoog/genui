// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../model/catalog_item.dart';
import '../../../model/v0_9/schemas.dart';
import '../../core_widgets/impl/video_impl.dart';

final _schema = S.object(
  properties: {
    'url': Schemas.stringReference(
      description: 'The URL of the video to play.',
    ),
  },
  required: ['url'],
);

/// A catalog item representing a video player.
///
/// This widget currently displays a placeholder for a video player. It is
/// intended to play video content from the given `url`.
///
/// ## Parameters:
///
/// - `url`: The URL of the video to play.
final video = CatalogItem(
  name: 'Video',
  dataSchema: _schema,
  widgetBuilder: videoBuilder,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": "Video",
          "url": {
            "literalString": "https://example.com/video.mp4"
          }
        }
      ]
    ''',
  ],
);
