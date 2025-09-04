// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../genui_client.dart';

class GenUIClient {
  final String _baseUrl;
  final http.Client _client;

  GenUIClient({String baseUrl = 'http://localhost:3400'})
    : _baseUrl = baseUrl,
      _client = http.Client();

  @visibleForTesting
  GenUIClient.withClient(
    http.Client client,
    {
    String baseUrl = 'http://localhost:3400',
  })
    : _baseUrl = baseUrl,
       _client = client;

  Future<String> startSession(Catalog catalog) async {
    final catalogSchema = catalog.schema;
    genUiLogger.info('Starting session with catalog schema: $catalogSchema');

    Object? toEncodable(Object? object) {
      if (object is Schema) {
        return object.toJson();
      }
      return object;
    }

    final requestBody = jsonEncode({
      'data': {
        'protocolVersion': '0.1.0',
        'catalog': catalogSchema,
      },
    }, toEncodable: toEncodable);
    genUiLogger.info('Request body: $requestBody');
    final response = await _client.post(
      Uri.parse('$_baseUrl/startSession'),
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    );

    genUiLogger.info('Response status code: ${response.statusCode}');
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as Map<String, Object?>)['result']
          as String;
    } else {
      var prettyJson = '';
      try {
        prettyJson = const JsonEncoder.withIndent(
          '  ',
        ).convert(jsonDecode(response.body));
      } on FormatException {
        prettyJson = response.body;
      }
      throw Exception('Failed to start session: $prettyJson');
    }
  }

  /// Generates a UI by sending the current conversation to the GenUI server.
  ///
  /// This method returns a stream of [ChatMessage]s. These can be either
  /// [AiUiMessage]s containing UI definitions as they are generated, or a final
  /// [AiTextMessage] from the model.
  Stream<ChatMessage> generateUI(
    String sessionId,
    List<ChatMessage> conversation,
  ) async* {
    final request = http.Request('POST', Uri.parse('$_baseUrl/generateUi'));
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      'data': {
        'sessionId': sessionId,
        'conversation': conversation.map((m) => m.toJson()).toList(),
      },
    });

    final response = await _client.send(request);

    if (response.statusCode == 200) {
      await for (final chunk in response.stream) {
        final decoded = utf8.decode(chunk);
        // Genkit streams can sometimes send multiple JSON objects
        for (final line in decoded.split('\n').where((s) => s.isNotEmpty)) {
          final json = jsonDecode(line) as Map<String, Object?>;

          // Handle toolRequest chunks for UI updates
          if (json['type'] == 'toolRequest') {
            final toolRequests = json['toolRequests'] as List<Object?>;
            for (final toolRequest in toolRequests) {
              final toolMap = toolRequest as Map<String, Object?>;
              final toolName = toolMap['name'] as String;
              if (toolName == 'addOrUpdateSurface' ||
                  toolName == 'deleteSurface') {
                final definition =
                    (toolMap['input'] as Map<String, Object?>)['definition']
                        as Map<String, Object?>;
                yield AiUiMessage(definition: definition);
              }
            }
            // Handle final text chunks
          } else if (json.containsKey('text')) {
            final text = json['text'] as String;
            if (text.isNotEmpty) {
              yield AiTextMessage.text(text);
            }
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
