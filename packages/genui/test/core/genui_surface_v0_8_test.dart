// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui/src/model/v0_9/messages.dart' as v0_9;

void main() {
  late A2uiMessageProcessor manager;
  final testCatalog = Catalog(
    [CoreCatalogItems.button, CoreCatalogItems.text],
    catalogId: standardCatalogId,
    binderFactory: V08DataBinder.new,
  );

  setUp(() {
    manager = A2uiMessageProcessor(catalogs: [testCatalog]);
  });

  testWidgets('SurfaceWidget builds a widget from a definition (v0.8)', (
    WidgetTester tester,
  ) async {
    const surfaceId = 'testSurface';
    final components = [
      const Component(
        id: 'root',
        props: {
          'component': {
            'Button': {
              'child': 'text',
              'action': {'name': 'testAction'},
            },
          },
        },
      ),
      const Component(
        id: 'text',
        props: {
          'component': {
            'Text': {
              'text': {'literalString': 'Hello'},
            },
          },
        },
      ),
    ];
    manager.handleMessage(
      v0_9.UpdateComponents(surfaceId: surfaceId, components: components),
    );
    manager.handleMessage(
      const v0_9.CreateSurface(
        surfaceId: surfaceId,
        catalogId: standardCatalogId,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GenUiSurface(host: manager, surfaceId: surfaceId),
      ),
    );

    expect(find.text('Hello'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('SurfaceWidget handles events (v0.8)', (
    WidgetTester tester,
  ) async {
    const surfaceId = 'testSurface';
    final components = [
      const Component(
        id: 'root',
        props: {
          'component': {
            'Button': {
              'child': 'text',
              'action': {'name': 'testAction'},
            },
          },
        },
      ),
      const Component(
        id: 'text',
        props: {
          'component': {
            'Text': {
              'text': {'literalString': 'Hello'},
            },
          },
        },
      ),
    ];
    manager.handleMessage(
      v0_9.UpdateComponents(surfaceId: surfaceId, components: components),
    );
    manager.handleMessage(
      const v0_9.CreateSurface(
        surfaceId: surfaceId,
        catalogId: standardCatalogId,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GenUiSurface(host: manager, surfaceId: surfaceId),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
  });
}
