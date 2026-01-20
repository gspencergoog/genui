// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  group('UI Tools', () {
    late A2uiMessageProcessor a2uiMessageProcessor;
    late Catalog catalog;

    setUp(() {
      catalog = CoreCatalogItems.asCatalog();
      a2uiMessageProcessor = A2uiMessageProcessor(catalogs: [catalog]);
    });

    test('UpdateComponentsTool sends UpdateComponents message', () async {
      final tool = UpdateComponentsTool(
        handleMessage: a2uiMessageProcessor.handleMessage,
        catalog: catalog,
      );

      final Map<String, Object> args = {
        surfaceIdKey: 'testSurface',
        'components': [
          {
            'id': 'root',
            // v0.9 flattened
            'type': 'Text',
            'text': {'literalString': 'Hello'},
          },
        ],
      };

      final Future<void> future = expectLater(
        a2uiMessageProcessor.surfaceUpdates,
        emitsInOrder([
          isA<SurfaceAdded>(),
          isA<SurfaceUpdated>()
              .having((e) => e.surfaceId, surfaceIdKey, 'testSurface')
              .having(
                (e) => e.definition.components.length,
                'components.length',
                1,
              )
              .having(
                (e) => e.definition.components.values.first.id,
                'components.first.id',
                'root',
              ),
        ]),
      );

      // Must create surface first in v0.9
      a2uiMessageProcessor.handleMessage(
        const CreateSurface(surfaceId: 'testSurface', catalogId: 'default'),
      );

      await tool.invoke(args);

      await future;
    });

    test('CreateSurfaceTool sends CreateSurface message', () async {
      final tool = CreateSurfaceTool(
        handleMessage: a2uiMessageProcessor.handleMessage,
      );

      final Map<String, Object?> args = {
        surfaceIdKey: 'testSurface',
        'catalogId': 'test_catalog',
        'theme': null,
        'attachDataModel': false,
      };

      // Use expectLater to wait for the stream to emit the correct event.
      final Future<void> future = expectLater(
        a2uiMessageProcessor.surfaceUpdates,
        emits(
          isA<SurfaceAdded>()
              .having((e) => e.surfaceId, surfaceIdKey, 'testSurface')
              .having(
                (e) => e.definition.rootComponentId,
                'rootComponentId',
                'root',
              )
              .having(
                (e) => e.definition.catalogId,
                'catalogId',
                'test_catalog',
              ),
        ),
      );

      await tool.invoke(args);

      await future; // Wait for the expectation to be met.
    });
  });
}
