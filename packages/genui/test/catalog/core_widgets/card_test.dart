// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  testWidgets('Card widget renders child', (WidgetTester tester) async {
    final manager = A2uiMessageProcessor(
      catalogs: [
        Catalog([
          CoreCatalogItems.card,
          CoreCatalogItems.text,
        ], catalogId: 'test_catalog'),
      ],
    );
    const surfaceId = 'testSurface';
    final components = [
      const Component(
        id: 'root',
        componentProperties: {'type': 'Card', 'child': 'text'},
      ),
      const Component(
        id: 'text',
        componentProperties: {'type': 'Text', 'text': 'This is a card.'},
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

    expect(find.text('This is a card.'), findsOneWidget);
    expect(find.byType(Card), findsOneWidget);
  });
}
