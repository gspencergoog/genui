// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui/src/model/v0_8/messages.dart' as v0_8;

void main() {
  testWidgets('List widget renders children', (WidgetTester tester) async {
    final manager = A2uiMessageProcessor(
      catalogs: [
        Catalog(
          [CoreCatalogItems.list, CoreCatalogItems.text],
          catalogId: standardCatalogId,
          binderFactory: V08DataBinder.new,
        ),
      ],
    );
    const surfaceId = 'testSurface';
    final components = [
      const Component(
        id: 'root',
        componentProperties: {
          'component': {
            'List': {
              'children': {
                'explicitList': ['text1', 'text2'],
              },
            },
          },
        },
      ),
      const Component(
        id: 'text1',
        componentProperties: {
          'component': {
            'Text': {
              'text': {'literalString': 'First'},
            },
          },
        },
      ),
      const Component(
        id: 'text2',
        componentProperties: {
          'component': {
            'Text': {
              'text': {'literalString': 'Second'},
            },
          },
        },
      ),
    ];
    manager.handleMessage(
      v0_8.SurfaceUpdate(surfaceId: surfaceId, components: components),
    );
    manager.handleMessage(
      const v0_8.BeginRendering(
        root: 'root',
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

    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
  });
}
