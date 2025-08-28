// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui_client/genui_client.dart';
import 'package:genui_client/genui_client_core.dart';

void main() {
  group('GenUiManager', () {
    late GenUiManager manager;

    setUp(() {
      manager = GenUiManager();
    });

    tearDown(() {
      manager.dispose();
    });

    test('constructor uses core catalog by default', () {
      expect(manager.catalog, coreCatalog);
    });

    test('constructor uses provided catalog', () {
      final catalog = const Catalog([]);
      final managerWithCatalog = GenUiManager(catalog: catalog);
      expect(managerWithCatalog.catalog, catalog);
    });

    test('surface() returns a notifier', () {
      final notifier = manager.surface('test_surface');
      expect(notifier, isNotNull);
      expect(manager.surfaces['test_surface'], notifier);
    });

    test('addOrUpdateSurface() adds a surface', () {
      const surfaceId = 'test_surface';
      final definition = {
        'root': 'root_widget',
        'widgets': [
          {
            'id': 'root_widget',
            'widget': {
              'Text': {'text': 'Hello'},
            },
          },
        ],
      };

      manager.addOrUpdateSurface(surfaceId, definition);

      final notifier = manager.surface(surfaceId);
      expect(notifier.value, isNotNull);
      expect(notifier.value!.surfaceId, surfaceId);
    });

    test('deleteSurface() removes a surface', () {
      const surfaceId = 'test_surface';
      final definition = {
        'root': 'root_widget',
        'widgets': [
          {
            'id': 'root_widget',
            'widget': {
              'Text': {'text': 'Hello'},
            },
          },
        ],
      };
      manager.addOrUpdateSurface(surfaceId, definition);

      manager.deleteSurface(surfaceId);

      expect(manager.surfaces.containsKey(surfaceId), isFalse);
    });
  });
}
