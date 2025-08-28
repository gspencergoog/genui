// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui_client/genui_client.dart';
import 'package:genui_client/genui_client_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('GenUIClient', () {
    test('startSession succeeds', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), 'http://localhost:3405/startSession');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['protocolVersion'], '0.1.0');
        expect(body['catalog'], isA<Map>());
        return http.Response(jsonEncode({'result': 'test_session_id'}), 200);
      });

      final client = GenUIClient.withClient(mockClient);
      final sessionId = await client.startSession(const Catalog([]));

      expect(sessionId, 'test_session_id');
    });

    test('startSession fails', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server error', 500);
      });

      final client = GenUIClient.withClient(mockClient);

      expect(
        () => client.startSession(const Catalog([])),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString()',
            'Exception: Failed to start session: Server error',
          ),
        ),
      );
    });

    test('generateUI succeeds', () async {
      final mockClient = MockClient.streaming((request, bodyStream) async {
        expect(request.url.toString(), 'http://localhost:3405/generateUi');
        expect(request.method, 'POST');
        final body =
            jsonDecode(await bodyStream.bytesToString())
                as Map<String, dynamic>;
        expect(body['sessionId'], 'test_session_id');
        expect(body['conversation'], isA<List<dynamic>>());

        final stream = Stream.fromIterable([
          utf8.encode(
            jsonEncode({
              'type': 'toolRequest',
              'toolRequests': <Map<String, Object?>>[
                {
                  'input': {
                    'definition': {
                      'surfaceId': 'surface1',
                      'root': 'root1',
                      'widgets': <Map<String, Object?>>[],
                    },
                  },
                },
              ],
            }),
          ),
          utf8.encode(
            jsonEncode({
              'type': 'toolRequest',
              'toolRequests': <Map<String, Object?>>[
                {
                  'input': {
                    'definition': {
                      'surfaceId': 'surface2',
                      'root': 'root2',
                      'widgets': <Map<String, Object?>>[],
                    },
                  },
                },
              ],
            }),
          ),
        ]);
        return http.StreamedResponse(stream, 200);
      });

      final client = GenUIClient.withClient(mockClient);
      final stream = client.generateUI('test_session_id', []);

      final definitions = await stream.toList();

      expect(definitions.length, 2);
      expect(definitions[0].surfaceId, 'surface1');
      expect(definitions[0].root, 'root1');
      expect(definitions[1].surfaceId, 'surface2');
      expect(definitions[1].root, 'root2');
    });

    test('generateUI fails', () async {
      final mockClient = MockClient.streaming((request, bodyStream) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode('Server error')),
          500,
        );
      });

      final client = GenUIClient.withClient(mockClient);
      final stream = client.generateUI('test_session_id', []);

      expect(
        stream.toList,
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString()',
            'Exception: Failed to generate UI: Server error',
          ),
        ),
      );
    });
  });
}
