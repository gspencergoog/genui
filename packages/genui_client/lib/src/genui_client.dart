// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../genui_client.dart';

class GenUIClient {
  final String _baseUrl;
  final http.Client _client;

  GenUIClient({String baseUrl = 'http://localhost:3405'})
    : _baseUrl = baseUrl,
      _client = http.Client();

  @visibleForTesting
  GenUIClient.withClient(
    http.Client client, {
    String baseUrl = 'http://localhost:3405',
  }) : _baseUrl = baseUrl,
       _client = client;

  Future<String> startSession(Catalog catalog) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/startSession'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'protocolVersion': '0.1.0', 'catalog': catalog.schema}),
    );

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as Map<String, Object?>)['result']
          as String;
    } else {
      throw Exception('Failed to start session: ${response.body}');
    }
  }

  /// Generates a UI by sending the current conversation to the GenUI server.
  ///
  /// This method returns a stream of [UiDefinition]s that represent the
  /// generated UI. The server may send multiple UI definitions in response to a
  /// single request.
  Stream<UiDefinition> generateUI(
    String sessionId,
    List<ChatMessage> conversation,
  ) async* {
    final request = http.Request('POST', Uri.parse('$_baseUrl/generateUi'));
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      'sessionId': sessionId,
      'conversation': conversation.map((m) => m.toJson()).toList(),
    });

    final response = await _client.send(request);

    if (response.statusCode == 200) {
      await for (final chunk in response.stream) {
        final decoded = utf8.decode(chunk);
        final json = jsonDecode(decoded) as Map<String, Object?>;
        if (json['type'] == 'toolRequest') {
          final toolRequests = json['toolRequests'] as List<Object?>;
          for (final toolRequest in toolRequests) {
            final definition =
                ((toolRequest as Map<String, Object?>)['input']
                        as Map<String, Object?>)['definition']
                    as Map<String, Object?>;
            yield UiDefinition.fromMap(definition);
          }
        }
      }
    } else {
      throw Exception(
        'Failed to generate UI: ${await response.stream.bytesToString()}',
      );
    }
  }
}
