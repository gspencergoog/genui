// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart' as genui;
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import 'a2a/a2a.dart' hide AgentCard;
import 'a2a/a2a.dart' as a2a;

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
    A2AClient? client,
    String? contextId,
    this.protocolVersion = genui.A2uiProtocolVersion.v0_8,
  }) : _contextId = contextId,
       _protocol = genui.A2uiProtocol.fromVersion(protocolVersion) {
    this.client = client ?? A2AClient(url: url.toString());
  }

  /// The version of the A2UI protocol to use.
  final genui.A2uiProtocolVersion protocolVersion;

  final genui.A2uiProtocol _protocol;

  /// The URL of the A2UI Agent.
  final Uri url;

  final _controller = StreamController<genui.A2uiMessage>.broadcast();
  final _errorController = StreamController<Object>.broadcast();

  @visibleForTesting
  late A2AClient client;

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
  Future<String?> connectAndSend(
    genui.UserMessage message, {
    genui.A2UiClientCapabilities? clientCapabilities,
  }) async {
    final List<Part> parts = [];
    for (final genui.MessagePart part in message.parts) {
      if (part is genui.TextPart) {
        parts.add(Part.text(text: part.text));
      } else if (part is genui.ImagePart) {
        if (part.url != null) {
          parts.add(
            Part.file(
              file: FileType.uri(
                uri: part.url.toString(),
                mimeType: part.mimeType,
              ),
            ),
          );
        } else if (part.bytes != null) {
          parts.add(
            Part.file(
              file: FileType.bytes(
                bytes: base64Encode(part.bytes!),
                mimeType: part.mimeType,
              ),
            ),
          );
        } else if (part.base64 != null) {
          parts.add(
            Part.file(
              file: FileType.bytes(
                bytes: part.base64!,
                mimeType: part.mimeType,
              ),
            ),
          );
        }
      }
    }

    final a2aMessage = Message(
      role: Role.user,
      parts: parts,
      messageId: const Uuid().v4(),
      contextId: _contextId,
      taskId: taskId,
      metadata: clientCapabilities != null
          ? {
              'clientUiCapabilities': {
                'supportedCatalogIds': clientCapabilities.supportedCatalogIds,
              },
            }
          : null,
    );

    _log.info('Sending A2A message: ${a2aMessage.messageId}');

    // Set extensions based on protocol version
    final List<String> extensions;
    if (protocolVersion == genui.A2uiProtocolVersion.v0_9) {
      extensions = ['https://a2ui.org/ext/a2a-ui/v0.9'];
    } else {
      extensions = ['https://a2ui.org/a2a-extension/a2ui/v0.8'];
    }
    final Message messageWithExtensions = a2aMessage.copyWith(
      extensions: extensions,
    );

    _log.info('--- OUTGOING REQUEST ---');
    _log.info('URL: ${url.toString()}');
    _log.info('Method: message/stream');
    String payload = const JsonEncoder.withIndent(
      '  ',
    ).convert(messageWithExtensions.toJson());
    _log.info('Payload: $payload');
    _log.info('----------------------');

    final Stream<Event> events = client.messageStream(messageWithExtensions);

    String? responseText;
    try {
      await for (final event in events) {
        _log.info('Received raw A2A event: ${event.toJson()}');
        const encoder = JsonEncoder.withIndent('  ');
        final String prettyJson = encoder.convert(event.toJson());
        _log.info('Received A2A event:\n$prettyJson');

        if (event is StatusUpdate) {
          taskId = event.taskId;
          _contextId = event.contextId;
          final Message? msg = event.status.message;
          if (msg != null) {
            final String msgPrettyJson = encoder.convert(msg.toJson());
            _log.info('Received A2A Message:\n$msgPrettyJson');
            for (final Part part in msg.parts) {
              if (part is DataPart) {
                processA2uiMessages(part.data);
              } else if (part is TextPart) {
                responseText = part.text;
              }
            }
          }
        } else if (event is TaskStatusUpdate) {
          taskId = event.taskId;
          _contextId = event.contextId;
          final Message? msg = event.status.message;
          if (msg != null) {
            final String msgPrettyJson = encoder.convert(msg.toJson());
            _log.info('Received A2A Message:\n$msgPrettyJson');
            for (final Part part in msg.parts) {
              if (part is DataPart) {
                processA2uiMessages(part.data);
              } else if (part is TextPart) {
                responseText = part.text;
              }
            }
          }
        }
      }
    } catch (e, s) {
      _log.severe('Error in A2A stream: $e', e, s);
      if (!_errorController.isClosed) {
        _errorController.add(e);
      }
    }
    return responseText;
  }

  /// Sends an event to the agent.
  ///
  /// This is used to send user interaction events to the agent, such as
  /// button clicks or form submissions.
  Future<void> sendEvent(genui.UiEvent event) async {
    if (taskId == null) {
      _log.severe('Cannot send event, no active task ID.');
      return;
    }

    // Convert UiEvent to map for logging (optional)
    final genui.JsonMap eventMap = event.toMap();

    _log.finest('Sending client event: $eventMap');

    final dataPart = Part.data(data: {'a2uiEvent': eventMap});
    final a2aMessage = Message(
      role: Role.user,
      parts: [dataPart],
      messageId: const Uuid().v4(),
      contextId: _contextId,
      taskId: taskId,
    );

    _log.info('Sending A2A event message: ${a2aMessage.messageId}');

    // Set extensions based on protocol version
    final List<String> extensions;
    if (protocolVersion == genui.A2uiProtocolVersion.v0_9) {
      extensions = ['https://a2ui.org/ext/a2a-ui/v0.9'];
    } else {
      extensions = ['https://a2ui.org/a2a-extension/a2ui/v0.8'];
    }
    final Message messageWithExtensions = a2aMessage.copyWith(
      extensions: extensions,
    );

    try {
      await client.messageSend(messageWithExtensions);
      _log.fine(
        'Successfully sent event for task $taskId (context $contextId)',
      );
    } catch (e) {
      _log.severe('Error sending event: $e');
    }
  }

  void processA2uiMessages(Map<String, Object?> data) {
    _log.finer(
      'Processing a2ui messages from data part:\n'
      '${const JsonEncoder.withIndent('  ').convert(data)}',
    );

    try {
      if (!_controller.isClosed) {
        final genui.A2uiMessage message = _protocol.parseJson(data);
        _log.finest(
          'Adding message to stream: '
          '${const JsonEncoder.withIndent('  ').convert(data)}',
        );
        _controller.add(message);
      }
    } on FormatException {
      _log.warning('A2A data part did not contain any known A2UI messages.');
    } catch (e) {
      _log.severe('Error parsing A2UI message from data part: $e');
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
