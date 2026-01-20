// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  group('Core Widgets', () {
    final Catalog testCatalog = CoreCatalogItems.asCatalog();

    ChatMessage? message;
    A2uiMessageProcessor? messageProcessor;

    Future<void> pumpWidgetWithDefinition(
      WidgetTester tester,
      List<Component> components,
    ) async {
      message = null;
      messageProcessor?.dispose();
      messageProcessor = A2uiMessageProcessor(catalogs: [testCatalog]);
      messageProcessor!.onSubmit.listen((event) => message = event);
      const surfaceId = 'testSurface';
      messageProcessor!.handleMessage(
        const CreateSurface(
          surfaceId: surfaceId,
          catalogId: standardCatalogId,
          theme: null,
          attachDataModel: true,
        ),
      );
      messageProcessor!.handleMessage(
        UpdateComponents(surfaceId: surfaceId, components: components),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GenUiSurface(host: messageProcessor!, surfaceId: surfaceId),
          ),
        ),
      );
    }

    testWidgets('Button renders and handles taps', (WidgetTester tester) async {
      final components = [
        const Component(
          id: 'root',
          componentProperties: {
            'type': 'Button',
            'child': 'text',
            'action': {'name': 'testAction'},
          },
        ),
        const Component(
          id: 'text',
          componentProperties: {
            'type': 'Text',
            'text': {'literalString': 'Click Me'},
          },
        ),
      ];

      await pumpWidgetWithDefinition(tester, components);

      expect(find.text('Click Me'), findsOneWidget);

      expect(message, null);
      await tester.tap(find.byType(ElevatedButton));
      expect(message, isNotNull);
    });

    testWidgets('Text renders from data model', (WidgetTester tester) async {
      final components = [
        const Component(
          id: 'root',
          componentProperties: {
            'type': 'Text',
            'text': {'path': '/myText'},
          },
        ),
      ];

      await pumpWidgetWithDefinition(tester, components);
      messageProcessor!
          .dataModelForSurface('testSurface')
          .update(DataPath('/myText'), 'Hello from data model');
      await tester.pumpAndSettle();

      expect(find.text('Hello from data model'), findsOneWidget);
    });

    testWidgets('Column renders children', (WidgetTester tester) async {
      final components = [
        const Component(
          id: 'root',
          componentProperties: {
            'type': 'Column',
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

      await pumpWidgetWithDefinition(tester, components);

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
    });

    testWidgets('TextField renders and handles changes/submissions', (
      WidgetTester tester,
    ) async {
      final components = [
        const Component(
          id: 'root',
          componentProperties: {
            'type': 'TextField',
            'text': {'path': '/myValue'},
            'label': {'literalString': 'My Label'},
            'onSubmittedAction': {'name': 'submit'},
          },
        ),
      ];

      await pumpWidgetWithDefinition(tester, components);
      messageProcessor!
          .dataModelForSurface('testSurface')
          .update(DataPath('/myValue'), 'initial');
      await tester.pumpAndSettle();

      final Finder textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      expect(find.text('initial'), findsOneWidget);
      // Verify ancestry explicitly if needed, but separate checks help debug.
      expect(
        find.descendant(of: textFieldFinder, matching: find.text('initial')),
        findsOneWidget,
      );
      final TextField textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.decoration?.labelText, 'My Label');

      // Test onChanged
      await tester.enterText(textFieldFinder, 'new value');
      expect(
        messageProcessor!
            .dataModelForSurface('testSurface')
            .getValue<String>(DataPath('/myValue')),
        'new value',
      );

      // Test onSubmitted
      expect(message, null);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(message, isNotNull);
    });
  });
}
