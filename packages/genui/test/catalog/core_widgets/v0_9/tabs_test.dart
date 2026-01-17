// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui/src/model/v0_9/messages.dart' as v0_9;

void main() {
  testWidgets('Tabs widget renders and handles taps', (
    WidgetTester tester,
  ) async {
    final manager = A2uiMessageProcessor(
      catalogs: [
        Catalog(
          [CoreCatalogItems.tabs, CoreCatalogItems.text],
          catalogId: standardCatalogId,
          binderFactory: V09DataBinder.new,
          componentParser: const V09ComponentParser(),
        ),
      ],
    );
    const surfaceId = 'testSurface';
    final components = [
      const Component(
        id: 'root',
        componentProperties: {
          'component': 'Tabs',
          'tabItems': [
            {'title': 'Tab 1', 'child': 'text1'},
            {'title': 'Tab 2', 'child': 'text2'},
          ],
        },
      ),
      const Component(
        id: 'text1',
        componentProperties: {
          'component': 'Text',
          'text': 'This is the first tab.',
        },
      ),
      const Component(
        id: 'text2',
        componentProperties: {
          'component': 'Text',
          'text': 'This is the second tab.',
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
