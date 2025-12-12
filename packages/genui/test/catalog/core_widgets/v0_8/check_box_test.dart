// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui/src/model/v0_8/messages.dart' as v0_8;

void main() {
  testWidgets('CheckBox widget renders and handles changes', (
    WidgetTester tester,
  ) async {
    final manager = A2uiMessageProcessor(
      catalogs: [
        Catalog(
          [CoreCatalogItems.checkBox],
          catalogId: standardCatalogId,
          binderFactory: V09DataBinder.new,
        ),
      ],
    );
    const surfaceId = 'testSurface';
    final components = [
      const Component(
        id: 'root',
        props: {
          'component': 'CheckBox',
          'label': {'literalString': 'Check me'},
          'value': {'path': '/myValue'},
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
    manager.dataModelForSurface(surfaceId).update(DataPath('/myValue'), true);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GenUiSurface(host: manager, surfaceId: surfaceId),
        ),
      ),
    );

    expect(find.text('Check me'), findsOneWidget);
    final CheckboxListTile checkbox = tester.widget<CheckboxListTile>(
      find.byType(CheckboxListTile),
    );
    expect(checkbox.value, isTrue);

    await tester.tap(find.byType(CheckboxListTile));
    expect(
      manager
          .dataModelForSurface(surfaceId)
          .getValue<bool>(DataPath('/myValue')),
      isFalse,
    );
  });
}
