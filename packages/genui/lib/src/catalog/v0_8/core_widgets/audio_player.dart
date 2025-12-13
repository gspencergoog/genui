// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../model/catalog_item.dart';
import '../../../model/v0_8/schemas.dart';
import '../../core_widgets/impl/audio_player_impl.dart';

final _schema = S.object(
  properties: {
    'url': A2uiSchemas.stringReference(
      description: 'The URL of the audio to play.',
    ),
  },
  required: ['url'],
);

/// A catalog item for an audio player.
///
/// This widget displays a placeholder for an audio player, used to represent
/// a component capable of playing audio from a given URL.
///
/// ## Parameters:
///
/// - `url`: The URL of the audio to play.
final audioPlayer = CatalogItem(
  name: 'AudioPlayer',
  dataSchema: _schema,
  widgetBuilder: audioPlayerBuilder,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "AudioPlayer": {
              "url": {
                "literalString": "https://example.com/audio.mp3"
              }
            }
          }
        }
      ]
    ''',
  ],
);
