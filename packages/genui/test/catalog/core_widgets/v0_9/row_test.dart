// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui/src/model/v0_9/messages.dart' as v0_9;

void main() {
  testWidgets('Row widget renders children', (WidgetTester tester) async {
    final manager = A2uiMessageProcessor(
      catalogs: [
        Catalog(
          [CoreCatalogItems.row, CoreCatalogItems.text],
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
          'component': 'Row',
          'children': {
            'explicitList': ['text1', 'text2'],
          },
        },
      ),
      const Component(
        id: 'text1',
        componentProperties: {'component': 'Text', 'text': 'First'},
      ),
      const Component(
        id: 'text2',
        componentProperties: {'component': 'Text', 'text': 'Second'},
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

  testWidgets('Row widget applies weight property to children', (
    WidgetTester tester,
  ) async {
    final manager = A2uiMessageProcessor(
      catalogs: [
        Catalog(
          [CoreCatalogItems.row, CoreCatalogItems.text],
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
          'component': 'Row',
          'children': {
            'explicitList': ['text1', 'text2', 'text3'],
          },
        },
      ),
      const Component(
        id: 'text1',
        componentProperties: {'component': 'Text', 'text': 'First'},
        weight: 1,
      ),
      const Component(
        id: 'text2',
        componentProperties: {'component': 'Text', 'text': 'Second'},
        weight: 2,
      ),
      const Component(
        id: 'text3',
        componentProperties: {'component': 'Text', 'text': 'Third'},
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

  // Verify that Row handles unbounded vertical constraints + stretch safely
  testWidgets(
    '''Row widget forces start alignment if height is unbounded and alignment is stretch''',
    (WidgetTester tester) async {
      final manager = A2uiMessageProcessor(
        catalogs: [
          Catalog(
            [
              CoreCatalogItems.row,
              CoreCatalogItems.column,
              CoreCatalogItems.text,
            ],
            catalogId: standardCatalogId,
            binderFactory: V09DataBinder.new,
            componentParser: const V09ComponentParser(),
          ),
        ],
      );
      const surfaceId = 'testSurface';
      // Similar structure to the reproduction test
      final components = [
        const Component(
          id: 'root',
          componentProperties: {
            'component': 'Column',
            'alignment': 'stretch',
            'children': ['row'],
          },
        ),
        const Component(
          id: 'row',
          componentProperties: {
            'component': 'Row',
            'alignment':
                // Should be converted to start due to unbounded height.
                'stretch',
            'children': ['col1', 'col2'],
          },
        ),
        const Component(
          id: 'col1',
          componentProperties: {
            'component': 'Column',
            'children': ['text1'],
          },
        ),
        const Component(
          id: 'text1',
          componentProperties: {'component': 'Text', 'text': 'Col 1'},
        ),
        const Component(
          id: 'col2',
          componentProperties: {
            'component': 'Column',
            'children': ['text2'],
          },
        ),
        const Component(
          id: 'text2',
          componentProperties: {'component': 'Text', 'text': 'Col 2'},
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

      // Use ListView to provide unbounded height
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [GenUiSurface(host: manager, surfaceId: surfaceId)],
            ),
          ),
        ),
      );

      // Should not crash
      expect(find.text('Col 1'), findsOneWidget);
      expect(find.text('Col 2'), findsOneWidget);
    },
  );
}
