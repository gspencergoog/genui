// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  testWidgets('Tabs widget renders and handles taps', (
    WidgetTester tester,
  ) async {
    final manager = A2uiMessageProcessor(
      catalogs: [
        Catalog([
          CoreCatalogItems.tabs,
          CoreCatalogItems.text,
        ], catalogId: 'test_catalog'),
      ],
    );
    const surfaceId = 'testSurface';
    final components = [
      const Component(
        id: 'root',
        componentProperties: {
          'type': 'Tabs',
          'tabItems': [
            {'title': 'Tab 1', 'child': 'tab1'},
            {'title': 'Tab 2', 'child': 'tab2'},
          ],
        },
      ),
      const Component(
        id: 'tab1',
        componentProperties: {'type': 'Text', 'text': 'This is the first tab.'},
      ),
      const Component(
        id: 'tab2',
        componentProperties: {
          'type': 'Text',
          'text': 'This is the second tab.',
        },
      ),
    ];
    manager.handleMessage(
      const CreateSurface(
        surfaceId: surfaceId,
        catalogId: 'test_catalog',
        theme: null,
      ),
    );
    manager.handleMessage(
      UpdateComponents(surfaceId: surfaceId, components: components),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GenUiSurface(host: manager, surfaceId: surfaceId),
        ),
      ),
    );

    expect(find.text('Tab 1'), findsOneWidget);
    expect(find.text('Tab 2'), findsOneWidget);
    expect(find.text('This is the first tab.'), findsOneWidget);
    expect(find.text('This is the second tab.'), findsNothing);

    await tester.tap(find.text('Tab 2'));
    await tester.pumpAndSettle();

    expect(find.text('This is the first tab.'), findsNothing);
    expect(find.text('This is the second tab.'), findsOneWidget);
  });
}
