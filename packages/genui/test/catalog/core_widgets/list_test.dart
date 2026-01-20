// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  testWidgets('List widget renders children', (WidgetTester tester) async {
    final manager = A2uiMessageProcessor(
      catalogs: [
        Catalog([
          CoreCatalogItems.list,
          CoreCatalogItems.text,
        ], catalogId: 'test_catalog'),
      ],
    );
    const surfaceId = 'testSurface';
    final components = [
      const Component(
        id: 'root',
        componentProperties: {
          'type': 'List',
          'children': {
            'explicitList': ['text1', 'text2'],
          },
        },
      ),
      const Component(
        id: 'text1',
        componentProperties: {
          'type': 'Text',
          'text': {'literalString': 'First'},
        },
      ),
      const Component(
        id: 'text2',
        componentProperties: {
          'type': 'Text',
          'text': {'literalString': 'Second'},
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

    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
  });
}
