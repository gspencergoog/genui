// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

/// A class to hold agent metadata.
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

/// An abstract interface for connecting to a GULF-compliant backend.
abstract class GulfConnector {
  /// The stream of GULF protocol lines (JSONL).
  Stream<String> get stream;

  /// Fetches metadata about the agent.
  Future<AgentCard> getAgentCard();

  /// Establishes a connection and sends the initial user message.
  ///
  /// The server's response will be delivered via the [stream]. An optional
  /// [onResponse] callback can be provided for direct text replies from the agent.
  Future<void> connectAndSend(
    String messageText, {
    void Function(String)? onResponse,
  });

  /// Sends a user interaction event to the agent.
  Future<void> sendEvent(Map<String, dynamic> event);

  /// Closes the connection and releases resources.
  void dispose();
}
