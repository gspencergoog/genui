// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui/src/model/v0_9/messages.dart' as v0_9;
import 'package:genui/src/model/v0_9/protocol.dart';

void main() {
  group('A2uiProtocolV09', () {
    const protocol = A2uiProtocolV09();

    test('version is v0_9', () {
      expect(protocol.version, A2uiProtocolVersion.v0_9);
    });

    test('parses UpdateComponents', () async {
      final Map<String, Map<String, Object>> json = {
        'updateComponents': {
          'surfaceId': '123',
          'components': [
            {
              'id': 'btn',
              'props': {'component': 'Button'},
            },
          ],
        },
      };
      final Stream<A2uiMessage> stream = protocol.parsePayload(json);
      final A2uiMessage message = await stream.single;
      expect(message, isA<v0_9.UpdateComponents>());
      final update = message as v0_9.UpdateComponents;
      expect(update.surfaceId, '123');
      expect(update.components.length, 1);
    });

    test('parses CreateSurface', () async {
      final json = {
        'createSurface': {'surfaceId': '123', 'catalogId': 'cat1'},
      };
      final Stream<A2uiMessage> stream = protocol.parsePayload(json);
      final A2uiMessage message = await stream.single;
      expect(message, isA<v0_9.CreateSurface>());
      final create = message as v0_9.CreateSurface;
      expect(create.surfaceId, '123');
      expect(create.catalogId, 'cat1');
    });

    test('parses UpdateDataModel', () async {
      final json = {
        'updateDataModel': {
          'surfaceId': '123',
          'path': '/foo',
          'value': 'bar',
          'op': 'replace',
        },
      };
      final Stream<A2uiMessage> stream = protocol.parsePayload(json);
      final A2uiMessage message = await stream.single;
      expect(message, isA<v0_9.UpdateDataModel>());
      final update = message as v0_9.UpdateDataModel;
      expect(update.surfaceId, '123');
      expect(update.path, '/foo');
      expect(update.value, 'bar');
      expect(update.op, 'replace');
    });

    test('parses JSONL string payload', () async {
      final String jsonLine = jsonEncode({
        'updateComponents': {'surfaceId': '123', 'components': <Object?>[]},
      });
      final Stream<A2uiMessage> stream = protocol.parsePayload('$jsonLine\n  ');
      final A2uiMessage message = await stream.single;
      expect(message, isA<v0_9.UpdateComponents>());
    });

    test('returns no tools', () {
      final catalog = const Catalog(
        [],
        catalogId: 'cat1',
        binderFactory: V09DataBinder.new,
      );
      final List<AiTool<JsonMap>> tools = protocol.getTools(catalog, (_) {});
      expect(tools, isEmpty);
    });

    test('returns non-null system preamble', () {
      final catalog = const Catalog(
        [],
        catalogId: 'cat1',
        binderFactory: V09DataBinder.new,
      );
      expect(protocol.getSystemPreamble(catalog), isNotEmpty);
      expect(protocol.getSystemPreamble(catalog), contains('JSONL'));
    });
  });
}
