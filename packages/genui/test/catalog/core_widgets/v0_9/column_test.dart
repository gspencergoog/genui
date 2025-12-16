// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui/src/model/v0_9/messages.dart' as v0_9;

void main() {
  testWidgets('Column widget renders children', (WidgetTester tester) async {
    final manager = A2uiMessageProcessor(
      catalogs: [
        Catalog(
          [CoreCatalogItems.column, CoreCatalogItems.text],
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
        props: {
          'component': 'Column',
          'children': {
            'explicitList': ['text1', 'text2'],
          },
        },
      ),
      const Component(
        id: 'text1',
        props: {'component': 'Text', 'text': 'First'},
      ),
      const Component(
        id: 'text2',
        props: {'component': 'Text', 'text': 'Second'},
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

    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
  });

  testWidgets('Column widget applies weight property to children', (
    WidgetTester tester,
  ) async {
    final manager = A2uiMessageProcessor(
      catalogs: [
        Catalog(
          [CoreCatalogItems.column, CoreCatalogItems.text],
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
        props: {
          'component': 'Column',
          'children': {
            'explicitList': ['text1', 'text2', 'text3'],
          },
        },
      ),
      const Component(
        id: 'text1',
        props: {'component': 'Text', 'text': 'First'},
        weight: 1,
      ),
      const Component(
        id: 'text2',
        props: {'component': 'Text', 'text': 'Second'},
        weight: 2,
      ),
      const Component(
        id: 'text3',
        props: {'component': 'Text', 'text': 'Third', 'weight': 0},
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

    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
    expect(find.text('Third'), findsOneWidget);

    final List<Flexible> flexibleWidgets = tester
        .widgetList<Flexible>(find.byType(Flexible))
        .toList();
    expect(flexibleWidgets.length, 2);

    // Check flex values
    expect(flexibleWidgets[0].flex, 1);
    expect(flexibleWidgets[1].flex, 2);

    // Check that the correct children are wrapped
    expect(
      find.ancestor(of: find.text('First'), matching: find.byType(Flexible)),
      findsOneWidget,
    );
    expect(
      find.ancestor(of: find.text('Second'), matching: find.byType(Flexible)),
      findsOneWidget,
    );
    expect(
      find.ancestor(of: find.text('Third'), matching: find.byType(Flexible)),
      findsNothing,
    );
  });

  // Verify that Column handles unbounded horizontal constraints + stretch safely
  testWidgets(
    'Column widget forces start alignment if width is unbounded and alignment is stretch',
    (WidgetTester tester) async {
      final manager = A2uiMessageProcessor(
        catalogs: [
          Catalog(
            [CoreCatalogItems.column, CoreCatalogItems.text],
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
          props: {
            'component': 'Column',
            'alignment':
                'stretch', // Should be converted to start due to unbounded width
            'children': ['text1'],
          },
        ),
        const Component(
          id: 'text1',
          props: {'component': 'Text', 'text': 'Test Text'},
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

      // Use SingleChildScrollView with horizontal scrolling to provide unbounded width
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: GenUiSurface(host: manager, surfaceId: surfaceId),
            ),
          ),
        ),
      );

      // Should not crash
      expect(find.text('Test Text'), findsOneWidget);
    },
  );
}
