// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui/src/model/v0_8/messages.dart' as v0_8;

void main() {
  testWidgets('Modal widget renders and handles taps', skip: true, (
    WidgetTester tester,
  ) async {
    final manager = A2uiMessageProcessor(
      catalogs: [
        Catalog(
          [
            CoreCatalogItems.modal,
            CoreCatalogItems.button,
            CoreCatalogItems.text,
          ],
          catalogId: standardCatalogId,
          binderFactory: V08DataBinder.new,
        ),
      ],
    );
    const surfaceId = 'testSurface';
    final components = [
      const Component(
        id: 'root',
        props: <String, Object?>{
          'component': <String, Object?>{
            'Modal': <String, Object?>{
              'entryPointChild': 'button',
              'contentChild': 'text',
            },
          },
        },
      ),
      const Component(
        id: 'button',
        props: <String, Object?>{
          'component': <String, Object?>{
            'Button': <String, Object?>{
              'child': 'button_text',
              'action': <String, Object?>{
                'name': 'showModal',
                'context': <String, Object?>{
                  'modalId': <String, Object?>{'literalString': 'root'},
                },
              },
            },
          },
        },
      ),
      const Component(
        id: 'button_text',
        props: <String, Object?>{
          'component': <String, Object?>{
            'Text': <String, Object?>{
              'text': <String, Object?>{'literalString': 'Open Modal'},
            },
          },
        },
      ),
      const Component(
        id: 'text',
        props: <String, Object?>{
          'component': <String, Object?>{
            'Text': <String, Object?>{
              'text': <String, Object?>{'literalString': 'This is a modal.'},
            },
          },
        },
      ),
    ];
    manager.handleMessage(
      const v0_8.BeginRendering(
        root: 'root',
        surfaceId: surfaceId,
        catalogId: standardCatalogId,
      ),
    );
    manager.handleMessage(
      v0_8.SurfaceUpdate(surfaceId: surfaceId, components: components),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GenUiSurface(host: manager, surfaceId: surfaceId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open Modal'), findsOneWidget);
    expect(find.text('This is a modal.'), findsNothing);

    await tester.tap(find.text('Open Modal'));
    await tester.pumpAndSettle();

    expect(find.text('This is a modal.'), findsOneWidget);
  });
}
