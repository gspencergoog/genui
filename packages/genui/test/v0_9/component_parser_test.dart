// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/src/model/v0_9/component_parser.dart';
import 'package:genui/src/primitives/simple_items.dart';

void main() {
  group('V09ComponentParser', () {
    const parser = V09ComponentParser();

    test('parses flattened component structure correctly', () {
      final Map<String, Object> data = {
        'id': 'btn1',
        'component': 'Button',
        'child': 'txt1',
        'action': {'name': 'click'},
      };

      final ({JsonMap widgetData, String? widgetType}) result = parser.parse(
        data,
      );

      expect(result.widgetType, equals('Button'));
      expect(result.widgetData, equals(data));
    });

    test('throws ArgumentError for nested component structure', () {
      final Map<String, Object> data = {
        'id': 'btn1',
        'component': {
          'Button': {'child': 'txt1'},
        },
      };

      expect(() => parser.parse(data), throwsArgumentError);
    });
  });
}
