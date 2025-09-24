// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'gulf_connector.dart';

final _log = Logger('GenkitGulfConnector');

/// Connects to a Genkit GULF server and streams the GULF protocol lines.
class GenkitGulfConnector implements GulfConnector {
  /// Creates a [GenkitGulfConnector] that connects to the given [url].
  GenkitGulfConnector({required this.url});

  /// The URL of the Genkit GULF server.
  final Uri url;

  final _controller = StreamController<String>.broadcast();
  http.Client? _client;
  final List<Map<String, dynamic>> _conversationHistory = [];

  @override
  Stream<String> get stream => _controller.stream;

  @override
  Future<AgentCard> getAgentCard() async {
    // The Genkit server doesn't have an agent card concept, so we return a
    // hardcoded one.
    return AgentCard(
      name: 'Genkit GULF Server',
      description: 'A Genkit-based server for the GULF protocol.',
      version: '1.0.0',
    );
  }

  @override
  Future<void> connectAndSend(
    String messageText, {
    void Function(String)? onResponse,
  }) async {
    _client = http.Client();
    _conversationHistory.add({
      'role': 'user',
      'parts': [
        {'text': messageText},
      ],
    });

    final request = http.Request('POST', url)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'catalog': <String, dynamic>{}, // The Genkit server doesn't use the catalog yet.
        'conversation': _conversationHistory,
      });

    try {
      final response = await _client!.send(request);

      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        final errorMessage = 'Failed to connect to Genkit server: '
            '${response.statusCode} $errorBody';
        _log.severe(errorMessage);
        if (!_controller.isClosed) {
          _controller.addError(errorMessage);
        }
        return;
      }

      response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              if (line.isNotEmpty && !_controller.isClosed) {
                _controller.add(line);
              }
            },
            onError: (Object error, StackTrace stackTrace) {
              if (!_controller.isClosed) {
                _controller.addError(error, stackTrace);
              }
            },
            onDone: () {
              if (!_controller.isClosed) {
                _controller.close();
              }
            },
          );
    } catch (e, s) {
      final errorMessage = 'Error sending message to Genkit server: $e';
      _log.severe(errorMessage, e, s);
      if (!_controller.isClosed) {
        _controller.addError(e, s);
      }
    }
  }

  @override
  Future<void> sendEvent(Map<String, dynamic> event) async {
    final clientEvent = {
      'actionName': event['action'],
      'sourceComponentId': event['sourceComponentId'],
      'timestamp': DateTime.now().toIso8601String(),
      'resolvedContext': event['context'],
    };

    _conversationHistory.add({
      'role': 'user',
      'parts': [
        {'gulfEvent': clientEvent},
      ],
    });

    // Resend the entire conversation with the new event.
    await connectAndSend('');
  }

  @override
  void dispose() {
    if (!_controller.isClosed) {
      _controller.close();
    }
    _client?.close();
  }
}
