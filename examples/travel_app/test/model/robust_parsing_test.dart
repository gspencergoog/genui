// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:travel_app/src/tools/booking/model.dart';

void main() {
  group('Robust Parsing', () {
    test('Component parses weight as double', () {
      final Map<String, Object> json = {
        'id': 'test_id',
        'weight': 1.0, // Double provided
        'component': {'type': 'TestComponent'},
      };

      final component = Component.fromJson(
        json,
        version: A2uiProtocolVersion.v0_8,
      );
      expect(component.weight, 1);
    });

    test('Component parses weight as int', () {
      final Map<String, Object> json = {
        'id': 'test_id',
        'weight': 2, // Int provided
        'component': {'type': 'TestComponent'},
      };

      final component = Component.fromJson(
        json,
        version: A2uiProtocolVersion.v0_8,
      );
      expect(component.weight, 2);
    });

    test('HotelSearch parses guests as double', () {
      final Map<String, Object> json = {
        'query': 'Paris',
        'checkIn': '2024-06-14',
        'checkOut': '2024-06-16',
        'guests': 2.0, // Double provided
      };

      final HotelSearch search = HotelSearch.fromJson(json);
      expect(search.guests, 2);
    });

    test('HotelSearch parses guests as int', () {
      final Map<String, Object> json = {
        'query': 'Paris',
        'checkIn': '2024-06-14',
        'checkOut': '2024-06-16',
        'guests': 3, // Int provided
      };

      final HotelSearch search = HotelSearch.fromJson(json);
      expect(search.guests, 3);
    });
  });
}
