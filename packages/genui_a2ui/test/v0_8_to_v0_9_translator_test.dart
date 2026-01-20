// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui_a2ui/src/v0_8_to_v0_9_translator.dart';

void main() {
  group('A2ui08To09Translator', () {
    final translator = A2ui08To09Translator();

    test('translateOne converts beginRendering to CreateSurface', () async {
      final v08Message = {
        'beginRendering': {
          'surfaceId': 'test_surface',
          'styles': {'color': 'red'},
        }
      };

      final messages = await translator.translateOne(v08Message).toList();
      expect(messages.length, 1);
      final msg = messages.first as CreateSurface;
      expect(msg.surfaceId, 'test_surface');
      expect(msg.theme, {'color': 'red'});
      expect(msg.catalogId, 'a2ui.org:standard_catalog_0_8_0');
      expect(msg.attachDataModel, isTrue);
    });

    test('translateOne converts surfaceUpdate to UpdateComponents (flattening props)', () async {
      final v08Message = {
        'surfaceUpdate': {
          'surfaceId': 'test_surface',
          'components': [
            {
              'id': 'comp1',
              'component': {
                'TextField': {
                  'label': 'My Label',
                  'text': 'Initial Value', // Should become value
                  'usageHint': 'outlined', // Should become variant
                }
              }
            }
          ]
        }
      };

      final messages = await translator.translateOne(v08Message).toList();
      expect(messages.length, 1);
      final msg = messages.first as UpdateComponents;
      expect(msg.surfaceId, 'test_surface');
      expect(msg.components.length, 1);

      final comp = msg.components.first;
      expect(comp.id, 'comp1');
      expect(comp.type, 'TextField');
      expect(comp.componentProperties['label'], 'My Label');
      expect(comp.componentProperties['value'], 'Initial Value'); // Renamed
      expect(comp.componentProperties['text'], isNull); // Removed
      expect(comp.componentProperties['variant'], 'outlined'); // Renamed
      expect(comp.componentProperties['usageHint'], isNull); // Removed
    });

    test('translateOne converts dataModelUpdate to UpdateDataModel', () async {
      final v08Message = {
        'dataModelUpdate': {
          'surfaceId': 'test_surface',
          'contents': [
            {'key': 'name', 'valueString': 'Alice'},
            {'key': 'age', 'valueInt': 30},
          ]
        }
      };

      final messages = await translator.translateOne(v08Message).toList();
      expect(messages.length, 1);
      final msg = messages.first as UpdateDataModel;
      expect(msg.surfaceId, 'test_surface');
      final valueMap = msg.value as Map<String, Object?>;
      expect(valueMap['name'], 'Alice');
      expect(valueMap['age'], 30);
    });
  });
}
