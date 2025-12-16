// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/src/model/v0_8/component_parser.dart';
import 'package:genui/src/primitives/simple_items.dart';

void main() {
  group('V08ComponentParser', () {
    const parser = V08ComponentParser();

    test('parses component with Map definition', () {
      final data = {
        'component': {
          'Button': {'label': 'Click me'},
        },
      };
      final ({JsonMap widgetData, String? widgetType}) result = parser.parse(
        data,
      );
      expect(result.widgetType, 'Button');
      expect(result.widgetData, {'label': 'Click me'});
    });

    test('throws ArgumentError for String component definition', () {
      final data = {'component': 'Button', 'label': 'Click me'};
      expect(
        () => parser.parse(data),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Component must be a map'),
          ),
        ),
      );
    });

    test('throws ArgumentError for invalid component type', () {
      final data = {'component': 123};
      expect(
        () => parser.parse(data),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Component must be a map'),
          ),
        ),
      );
    });

    test('throws ArgumentError for empty Map component', () {
      final data = {'component': <String, dynamic>{}};
      expect(
        () => parser.parse(data),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('No widget type found'),
          ),
        ),
      );
    });
  });
}
