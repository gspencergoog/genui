// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui/src/model/v0_9/messages.dart' as v0_9;

void main() {
  testWidgets('DateTimeInput widget renders and handles changes', (
    WidgetTester tester,
  ) async {
    final manager = A2uiMessageProcessor(
      catalogs: [
        Catalog(
          [CoreCatalogItems.dateTimeInput, CoreCatalogItems.text],
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
          'component': 'DateTimeInput',
          'value': {'path': '/myDateTime'},
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
    manager
        .dataModelForSurface(surfaceId)
        .update(DataPath('/myDateTime'), '2025-10-15');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GenUiSurface(host: manager, surfaceId: surfaceId),
        ),
      ),
    );

    expect(find.text('2025-10-15'), findsOneWidget);
  });
}
