// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/src/model/a2ui_protocol.dart';
import 'package:genui/src/model/ui_models.dart';
import 'package:genui/src/primitives/simple_items.dart';

void main() {
  group('UserActionEvent', () {
    test('can be created and read', () {
      final now = DateTime.now();
      final event = UserActionEvent(
        surfaceId: 'testSurface',
        name: 'testAction',
        sourceComponentId: 'testWidget',
        timestamp: now,
        context: {'key': 'value'},
      );

      expect(event.surfaceId, 'testSurface');
      expect(event.name, 'testAction');
      expect(event.sourceComponentId, 'testWidget');
      expect(event.timestamp, now);
      expect(event.isAction, isTrue);
      expect(event.context, {'key': 'value'});
    });

    test('can be created from map and read', () {
      final now = DateTime.now();
      final event = UserActionEvent.fromMap({
        surfaceIdKey: 'testSurface',
        'name': 'testAction',
        'sourceComponentId': 'testWidget',
        'timestamp': now.toIso8601String(),
        'isAction': true,
        'context': {'key': 'value'},
      });

      expect(event.surfaceId, 'testSurface');
      expect(event.name, 'testAction');
      expect(event.sourceComponentId, 'testWidget');
      expect(event.timestamp, now);
      expect(event.isAction, isTrue);
      expect(event.context, {'key': 'value'});
    });

    test('can be converted to map', () {
      final now = DateTime.now();
      final event = UserActionEvent(
        surfaceId: 'testSurface',
        name: 'testAction',
        sourceComponentId: 'testWidget',
        timestamp: now,
        context: {'key': 'value'},
      );

      final JsonMap map = event.toMap();

      expect(map[surfaceIdKey], 'testSurface');
      expect(map['name'], 'testAction');
      expect(map['sourceComponentId'], 'testWidget');
      expect(map['timestamp'], now.toIso8601String());
      expect(map['isAction'], isTrue);
      expect(map['context'], {'key': 'value'});
    });
  });

  group('Component', () {
    test('defaults to v0.8', () {
      const component = Component(id: 'test', props: {'foo': 'bar'});
      expect(component.version, A2uiProtocolVersion.v0_8);
      expect(component.toJson(), {'id': 'test', 'foo': 'bar'});
    });

    test('serializes v0.8 correctly', () {
      const component = Component(
        id: 'test',
        props: {'foo': 'bar'},
        version: A2uiProtocolVersion.v0_8,
      );
      expect(component.toJson(), {'id': 'test', 'foo': 'bar'});
    });

    test('serializes v0.9 correctly', () {
      const component = Component(
        id: 'test',
        props: {'foo': 'bar'},
        version: A2uiProtocolVersion.v0_9,
      );
      expect(component.toJson(), {
        'id': 'test',
        'props': {'foo': 'bar'},
      });
    });

    test('parses v0.8 correctly', () {
      final json = {'id': 'test', 'foo': 'bar'};
      final component = Component.fromJson(
        json,
        version: A2uiProtocolVersion.v0_8,
      );
      expect(component.id, 'test');
      expect(component.props, {'foo': 'bar'});
      expect(component.version, A2uiProtocolVersion.v0_8);
    });

    test('parses v0.9 correctly', () {
      final Map<String, Object> json = {
        'id': 'test',
        'props': {'foo': 'bar'},
      };
      final component = Component.fromJson(
        json,
        version: A2uiProtocolVersion.v0_9,
      );
      expect(component.id, 'test');
      expect(component.props, {'foo': 'bar'});
      expect(component.version, A2uiProtocolVersion.v0_9);
    });

    test('parses v0.9 with missing props correctly', () {
      final json = {'id': 'test'};
      final component = Component.fromJson(
        json,
        version: A2uiProtocolVersion.v0_9,
      );
      expect(component.id, 'test');
      expect(component.props, isEmpty);
      expect(component.version, A2uiProtocolVersion.v0_9);
    });
  });
}
