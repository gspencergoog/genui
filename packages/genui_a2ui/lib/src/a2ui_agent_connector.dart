// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:a2a_dart/a2a_dart.dart' as a2a;
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart' as genui;
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

final Logger _log = genui.genUiLogger;

/// A class to hold the agent card details.
class AgentCard {
  /// Creates a new [AgentCard] instance.
  AgentCard({
    required this.name,
    required this.description,
    required this.version,
  });

  /// The name of the agent.
  final String name;

  /// A description of the agent.
  final String description;

  /// The version of the agent.
  final String version;
}

/// Connects to an A2UI Agent endpoint and streams the A2UI protocol lines.
///
/// This class handles the communication with an A2UI agent, including fetching
/// the agent card, sending messages, and receiving the A2UI protocol stream.
class A2uiAgentConnector {
  /// Creates a [A2uiAgentConnector] that connects to the given [url].
  A2uiAgentConnector({
    required this.url,
    a2a.A2AClient? client,
    String? contextId,
  }) : _contextId = contextId {
    this.client = client ?? a2a.A2AClient(url: url.toString(), log: _log);
  }

  /// The URL of the A2UI Agent.
  final Uri url;

  final _controller = StreamController<genui.A2uiMessage>.broadcast();
  final _errorController = StreamController<Object>.broadcast();
  @visibleForTesting
  late a2a.A2AClient client;
  @visibleForTesting
  String? taskId;

  String? _contextId;
  String? get contextId => _contextId;

  /// The stream of A2UI protocol lines.
  ///
  /// This stream emits the JSONL messages from the A2UI protocol.
  Stream<genui.A2uiMessage> get stream => _controller.stream;

  /// A stream of errors from the A2A connection.
  Stream<Object> get errorStream => _errorController.stream;

  /// Fetches the agent card.
  ///
  /// The agent card contains metadata about the agent, such as its name,
  /// description, and version.
  Future<AgentCard> getAgentCard() async {
    // The A2AClient.getAgentCard returns an AgentCard from the a2a_dart
    // package. We map it to our local AgentCard class.
    final a2a.AgentCard card = await client.getAgentCard();
    return AgentCard(
      name: card.name,
      description: card.description,
      version: card.version,
    );
  }

  /// Connects to the agent and sends a message.
  ///
  /// Returns the text response from the agent, if any.
  Future<String?> connectAndSend(genui.ChatMessage chatMessage) async {
    final List<Object> parts = (chatMessage is genui.UserMessage)
        ? chatMessage.parts
        : (chatMessage is genui.UserUiInteractionMessage)
        ? chatMessage.parts
        : <a2a.Part>[];

    final List<a2a.Part> messageParts = parts.map<a2a.Part>((part) {
      switch (part) {
        case genui.TextPart():
          return a2a.Part.text(text: part.text);
        case genui.DataPart():
          return a2a.Part.data(data: part.data as Map<String, Object?>? ?? {});
        case genui.ImagePart():
          if (part.url != null) {
            return a2a.Part.file(
              file: a2a.FileType.uri(
                uri: part.url.toString(),
                mimeType: part.mimeType ?? 'image/jpeg',
              ),
            );
          } else {
            String base64Data;
            if (part.bytes != null) {
              base64Data = base64Encode(part.bytes!);
            } else if (part.base64 != null) {
              base64Data = part.base64!;
            } else {
              _log.warning('ImagePart has no data (url, bytes, or base64)');
              return const a2a.Part.text(text: '[Empty Image]');
            }
            return a2a.Part.file(
              file: a2a.FileType.bytes(
                bytes: base64Data,
                mimeType: part.mimeType ?? 'image/jpeg',
              ),
            );
          }
        default:
          _log.warning('Unknown message part type: ${part.runtimeType}');
          return const a2a.Part.text(text: '[Unknown Part]');
      }
    }).toList();

    final message = a2a.Message(
      messageId: const Uuid().v4(),
      role: a2a.Role.user,
      parts: messageParts,
      taskId: taskId,
      contextId: contextId,
      referenceTaskIds: taskId != null ? [taskId!] : null,
      extensions: ['https://a2ui.org/ext/a2a-ui/v0.1'],
    );

    _log.info('--- OUTGOING REQUEST ---');
    _log.info('URL: ${url.toString()}');
    _log.info('Method: message/stream');
    _log.info(
      'Payload: '
      '${const JsonEncoder.withIndent('  ').convert(message.toJson())}',
    );
    _log.info('----------------------');

    final Stream<a2a.Event> events = client.messageStream(message);

    String? responseText;
    try {
      a2a.Message? finalResponse;
      await for (final event in events) {
        _log.info('Received raw A2A event: ${event.toJson()}');
        const encoder = JsonEncoder.withIndent('  ');
        final String prettyJson = encoder.convert(event.toJson());
        _log.info('Received A2A event:\n$prettyJson');

        if (event is a2a.TaskStatusUpdate) {
          taskId = event.taskId;
          _contextId = event.contextId;

          final a2a.Message? message = event.status.message;
          if (message != null) {
            finalResponse = message;
            const encoder = JsonEncoder.withIndent('  ');
            final String prettyJson = encoder.convert(message.toJson());
            _log.info('Received A2A Message:\n$prettyJson');
            for (final a2a.Part part in message.parts) {
              if (part is a2a.DataPart) {
                _processA2uiMessages(part.data);
              }
            }
          }
        }
        // TODO: Handle TaskArtifactUpdate if needed.
      }

      if (finalResponse != null) {
        for (final a2a.Part part in finalResponse.parts) {
          if (part is a2a.TextPart) {
            responseText = part.text;
          }
        }
      }
    } on a2a.A2AException catch (e) {
      final String errorMessage = switch (e) {
        a2a.A2AJsonRpcException(:final code, :final message) =>
          'A2A Error: $message (code: $code)',
        a2a.A2AHttpException(:final statusCode, :final reason) =>
          'A2A HTTP Error: $statusCode ${reason ?? ''}',
        a2a.A2ANetworkException(:final message) =>
          'A2A Network Error: $message',
        a2a.A2AParsingException(:final message) =>
          'A2A Parsing Error: $message',
        _ => 'A2A Error: $e',
      };
      _log.severe(errorMessage);
      if (!_errorController.isClosed) {
        _errorController.add(errorMessage);
      }
    } on FormatException catch (e, s) {
      _log.severe('Error parsing A2A response: $e', e, s);
    } catch (e, s) {
      _log.severe('Unexpected error: $e', e, s);
      if (!_errorController.isClosed) {
        _errorController.add('Unexpected error: $e');
      }
    }
    return responseText;
  }

  /// Sends an event to the agent.
  ///
  /// This is used to send user interaction events to the agent, such as
  /// button clicks or form submissions.
  Future<void> sendEvent(Map<String, Object?> event) async {
    if (taskId == null) {
      _log.severe('Cannot send event, no active task ID.');
      return;
    }

    final Map<String, Object?> clientEvent = {
      'actionName': event['action'],
      'sourceComponentId': event['sourceComponentId'],
      'timestamp': DateTime.now().toIso8601String(),
      'resolvedContext': event['context'],
    };

    _log.finest('Sending client event: $clientEvent');

    final dataPart = a2a.Part.data(data: {'a2uiEvent': clientEvent});
    final message = a2a.Message(
      messageId: const Uuid().v4(),
      role: a2a.Role.user,
      parts: [dataPart],
      contextId: contextId,
      taskId: taskId,
      referenceTaskIds: [taskId!],
      extensions: ['https://a2ui.org/ext/a2a-ui/v0.1'],
    );

    try {
      await client.messageSend(message);
      _log.fine(
        'Successfully sent event for task $taskId (context $contextId)',
      );
    } catch (e) {
      _log.severe('Error sending event: $e');
    }
  }

  void _processA2uiMessages(Map<String, Object?> data) {
    _log.finer(
      'Processing a2ui messages from data part:\n'
      '${const JsonEncoder.withIndent('  ').convert(data)}',
    );
    if (data.containsKey('surfaceUpdate') ||
        data.containsKey('dataModelUpdate') ||
        data.containsKey('beginRendering') ||
        data.containsKey('deleteSurface')) {
      if (!_controller.isClosed) {
        _log.finest(
          'Adding message to stream: '
          '${const JsonEncoder.withIndent('  ').convert(data)}',
        );
        _controller.add(genui.A2uiMessage.fromJson(data));
      }
    } else {
      _log.warning('A2A data part did not contain any known A2UI messages.');
    }
  }

  /// Closes the connection to the agent.
  ///
  /// This should be called when the connector is no longer needed to release
  /// resources.
  void dispose() {
    if (!_controller.isClosed) {
      _controller.close();
    }
    if (!_errorController.isClosed) {
      _errorController.close();
    }
    client.close();
  }
}
