// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  group('A2uiProtocolV08', () {
    const protocol = A2uiProtocolV08();

    test('version is v0_8', () {
      expect(protocol.version, A2uiProtocolVersion.v0_8);
    });

    test('parses SurfaceUpdate', () async {
      final Map<String, Map<String, Object>> json = {
        'surfaceUpdate': {
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
      expect(message, isA<SurfaceUpdate>());
      final update = message as SurfaceUpdate;
      expect(update.surfaceId, '123');
      expect(update.components.length, 1);
      expect(update.components.first.id, 'btn');
    });

    test('parses BeginRendering', () async {
      final Map<String, Map<String, Object>> json = {
        'beginRendering': {
          'surfaceId': '123',
          'root': 'rootId',
          'styles': {'color': 'red'},
          'catalogId': 'cat1',
        },
      };
      final Stream<A2uiMessage> stream = protocol.parsePayload(json);
      final A2uiMessage message = await stream.single;
      expect(message, isA<BeginRendering>());
      final begin = message as BeginRendering;
      expect(begin.surfaceId, '123');
      expect(begin.root, 'rootId');
      expect(begin.styles, {'color': 'red'});
      expect(begin.catalogId, 'cat1');
    });

    test('parses DataModelUpdate', () async {
      final json = {
        'dataModelUpdate': {
          'surfaceId': '123',
          'path': '/foo',
          'contents': 'bar',
        },
      };
      final Stream<A2uiMessage> stream = protocol.parsePayload(json);
      final A2uiMessage message = await stream.single;
      expect(message, isA<DataModelUpdate>());
      final update = message as DataModelUpdate;
      expect(update.surfaceId, '123');
      expect(update.path, '/foo');
      expect(update.contents, 'bar');
    });

    test('parses SurfaceDeletion', () async {
      final json = {
        'deleteSurface': {'surfaceId': '123'},
      };
      final Stream<A2uiMessage> stream = protocol.parsePayload(json);
      final A2uiMessage message = await stream.single;
      expect(message, isA<DeleteSurface>());
      expect((message as DeleteSurface).surfaceId, '123');
    });

    test('parses string payload as JSON', () async {
      final String jsonString = jsonEncode({
        'surfaceUpdate': {'surfaceId': '123', 'components': <Object?>[]},
      });
      final Stream<A2uiMessage> stream = protocol.parsePayload(jsonString);
      final A2uiMessage message = await stream.single;
      expect(message, isA<SurfaceUpdate>());
    });

    test('returns correct tools', () {
      final catalog = const Catalog([], catalogId: 'cat1');
      final List<AiTool<JsonMap>> tools = protocol.getTools(catalog, (_) {});
      expect(
        tools.map((t) => t.name),
        containsAll([
          'surfaceUpdate',
          'beginRendering',
          'dataModelUpdate',
          'deleteSurface',
        ]),
      );
    });

    test('returns null system preamble', () {
      final catalog = const Catalog([], catalogId: 'cat1');
      expect(protocol.getSystemPreamble(catalog), isNull);
    });
  });
}
