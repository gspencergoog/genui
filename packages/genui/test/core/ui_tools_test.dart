// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui/src/model/v0_8/messages.dart' as v0_8;

void main() {
  group('UI Tools', () {
    late A2uiMessageProcessor genUiManager;
    late Catalog catalog;

    setUp(() {
      catalog = CoreCatalogItems.asCatalog();
      genUiManager = A2uiMessageProcessor(catalogs: [catalog]);
    });

    test('SurfaceUpdateTool sends SurfaceUpdate message', () async {
      final tool = SurfaceUpdateTool(
        handleMessage: genUiManager.handleMessage,
        catalog: catalog,
      );

      final Map<String, Object> args = {
        surfaceIdKey: 'testSurface',
        'components': [
          {'id': 'root', 'component': 'Text', 'text': 'Hello'},
        ],
      };

      final Future<void> future = expectLater(
        genUiManager.surfaceUpdates,
        emits(
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
        ),
      );

      await tool.invoke(args);
      // Trigger a render by setting root
      genUiManager.handleMessage(
        const v0_8.BeginRendering(
          surfaceId: 'testSurface',
          root: 'root',
          catalogId: standardCatalogId,
        ),
      );

      await future;
    });

    test('BeginRenderingTool sends BeginRendering message', () async {
      final tool = BeginRenderingTool(
        handleMessage: genUiManager.handleMessage,
        catalogId: standardCatalogId,
      );

      final Map<String, String> args = {
        surfaceIdKey: 'testSurface',
        'root': 'root',
      };

      // First, add a component to the surface so that the root can be set.
      genUiManager.handleMessage(
        const v0_8.SurfaceUpdate(
          surfaceId: 'testSurface',
          components: [
            Component(
              id: 'root',
              props: {'component': 'Text', 'text': 'Hello'},
              version: A2uiProtocolVersion.v0_8,
            ),
          ],
        ),
      );

      // Use expectLater to wait for the stream to emit the correct event.
      final Future<void> future = expectLater(
        genUiManager.surfaceUpdates,
        emits(
          isA<SurfaceAdded>().having(
            (e) => e.surfaceId,
            surfaceIdKey,
            'testSurface',
          ),
        ),
      );

      await tool.invoke(args);

      await future; // Wait for the expectation to be met.
    });
    test('DataModelUpdateTool updates data model with properly structured '
        'contents', () async {
      final tool = DataModelUpdateTool(
        handleMessage: genUiManager.handleMessage,
      );
      final Map<String, Object> args = {
        surfaceIdKey: 'testSurface',
        'path': 'user',
        'contents': [
          {'key': 'name', 'valueString': 'Alice'},
        ],
      };
      await tool.invoke(args);
      final DataModel dataModel = genUiManager.dataModelForSurface(
        'testSurface',
      );
      expect(dataModel.getValue<String>(DataPath('user/name')), 'Alice');
    });

    test(
      'DataModelUpdateTool updates data model with map in adjacency list',
      () async {
        final tool = DataModelUpdateTool(
          handleMessage: genUiManager.handleMessage,
        );
        final Map<String, Object> args = {
          surfaceIdKey: 'testSurface',
          'path': 'config',
          'contents': [
            {
              'key': 'theme',
              'valueMap': [
                {'key': 'mode', 'valueString': 'dark'},
                {'key': 'version', 'valueNumber': 1},
              ],
            },
          ],
        };
        await tool.invoke(args);
        final DataModel dataModel = genUiManager.dataModelForSurface(
          'testSurface',
        );
        // The DataModel implementation automatically converts the adjacency list into a standard Map/List structure.
        // So we can expect nested maps here.
        final Map<String, dynamic>? theme = dataModel
            .getValue<Map<String, dynamic>>(DataPath('config/theme'));
        expect(theme, {'mode': 'dark', 'version': 1});
      },
    );
  });
}
