// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui/src/model/v0_9/messages.dart' as v0_9;

void main() {
  testWidgets('Slider widget renders and handles changes', (
    WidgetTester tester,
  ) async {
    final manager = A2uiMessageProcessor(
      catalogs: [
        Catalog(
          [CoreCatalogItems.slider],
          catalogId: standardCatalogId,
          binderFactory: V09DataBinder.new,
          componentParser: const V09ComponentParser(),
        ),
      ],
    );
    const surfaceId = 'testSurface';
    final components = [
      const Component(
        version: A2uiProtocolVersion.v0_9,
        id: 'root',
        componentProperties: {
          'component': 'Slider',
          'value': {'path': '/myValue'},
          'min': {'literalNumber': 0.0},
          'max': {'literalNumber': 1.0},
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
    manager.dataModelForSurface(surfaceId).update(DataPath('/myValue'), 0.5);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GenUiSurface(host: manager, surfaceId: surfaceId),
        ),
      ),
    );

    final Slider slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, 0.5);

    await tester.drag(find.byType(Slider), const Offset(100, 0));
    expect(
      manager
          .dataModelForSurface(surfaceId)
          .getValue<double>(DataPath('/myValue')),
      greaterThan(0.5),
    );
  });

  testWidgets('Slider widget handles data-bound min/max values', (
    WidgetTester tester,
  ) async {
    final manager = A2uiMessageProcessor(
      catalogs: [
        Catalog(
          [CoreCatalogItems.slider],
          catalogId: standardCatalogId,
          binderFactory: V09DataBinder.new,
          componentParser: const V09ComponentParser(),
        ),
      ],
    );
    const surfaceId = 'testSurface';
    final components = [
      const Component(
        version: A2uiProtocolVersion.v0_9,
        id: 'root',
        componentProperties: {
          'component': 'Slider',
          'value': {'path': '/myValue'},
          'min': {'path': '/myMin'},
          'max': {'path': '/myMax'},
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
    manager.handleMessage(
      const v0_9.UpdateDataModel(
        surfaceId: surfaceId,
        value: {'myValue': 5.0, 'myMin': 0.0, 'myMax': 10.0},
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GenUiSurface(host: manager, surfaceId: surfaceId),
        ),
      ),
    );

    final Slider slider = tester.widget(find.byType(Slider));
    expect(slider.value, 5.0);
    expect(slider.min, 0.0);
    expect(slider.max, 10.0);

    // Update min/max via data model
    manager.handleMessage(
      const v0_9.UpdateDataModel(
        surfaceId: surfaceId,
        value: {'myMin': 2.0, 'myMax': 8.0},
      ),
    );
    await tester.pumpAndSettle();

    final Slider sliderUpdated = tester.widget(find.byType(Slider));
    expect(sliderUpdated.min, 2.0);
    expect(sliderUpdated.max, 8.0);
  });
}
