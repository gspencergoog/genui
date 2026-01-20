// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:genui/genui.dart' as genui;
import 'package:genui_a2ui/genui_a2ui.dart';
import 'package:genui_a2ui/src/a2a/a2a.dart' as a2a;

class FakeA2AClient implements a2a.A2AClient {
  a2a.AgentCard? agentCard;
  Stream<a2a.Event> Function(a2a.Message)? messageStreamHandler;
  Future<a2a.Task> Function(a2a.Message)? messageSendHandler;

  @override
  String get url => 'http://localhost:8080';

  int getAgentCardCalled = 0;
  int messageStreamCalled = 0;
  int messageSendCalled = 0;

  a2a.Message? lastMessageStreamParams;
  a2a.Message? lastMessageSendParams;

  @override
  Future<a2a.AgentCard> getAgentCard({
    String? agentBaseUrl,
    String? agentCardPath,
  }) async {
    getAgentCardCalled++;
    if (agentCard != null) {
      return agentCard!;
    }
    // Return a default card
    return const a2a.AgentCard(
      name: 'Test Agent',
      description: 'A test agent',
      version: '1.0.0',
      protocolVersion: '0.9.0',
      capabilities: a2a.AgentCapabilities(streaming: true),
      defaultInputModes: ['text/plain'],
      defaultOutputModes: ['text/plain'],
      skills: [],
      url: 'http://localhost:8080',
    );
  }

  @override
  Future<a2a.AgentCard> getAuthenticatedExtendedCard(String token) async {
    return getAgentCard();
  }

  @override
  Stream<a2a.Event> messageStream(a2a.Message message) {
    messageStreamCalled++;
    lastMessageStreamParams = message;
    if (messageStreamHandler != null) {
      return messageStreamHandler!(message);
    }
    return const Stream.empty();
  }

  @override
  Future<a2a.Task> messageSend(a2a.Message message) async {
    messageSendCalled++;
    lastMessageSendParams = message;
    if (messageSendHandler != null) {
      return messageSendHandler!(message);
    }
    // Default task response
    return const a2a.Task(
      id: 'task1',
      contextId: 'context1',
      status: a2a.TaskStatus(state: a2a.TaskState.completed),
    );
  }

  @override
  Future<a2a.Task> getTask(String taskId) async {
    throw UnimplementedError();
  }

  @override
  Future<a2a.ListTasksResult> listTasks([a2a.ListTasksParams? params]) async {
    throw UnimplementedError();
  }

  @override
  Future<a2a.Task> cancelTask(String taskId) async {
    throw UnimplementedError();
  }

  @override
  Stream<a2a.Event> resubscribeToTask(String taskId) {
    throw UnimplementedError();
  }

  @override
  void close() {}

  @override
  Future<a2a.TaskPushNotificationConfig> setPushNotificationConfig(
    a2a.TaskPushNotificationConfig params,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<List<a2a.PushNotificationConfig>> listPushNotificationConfigs(
    String taskId,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deletePushNotificationConfig(String taskId, String configId) {
    // TODO: implement deletePushNotificationConfig
    throw UnimplementedError();
  }

  @override
  Future<a2a.TaskPushNotificationConfig> getPushNotificationConfig(
    String taskId,
    String configId,
  ) {
    // TODO: implement getPushNotificationConfig
    throw UnimplementedError();
  }
}

class FakeA2uiAgentConnector implements A2uiAgentConnector {
  @override
  final Uri url;

  @override
  final genui.A2uiProtocolVersion protocolVersion;

  FakeA2uiAgentConnector({
    Uri? url,
    this.protocolVersion = genui.A2uiProtocolVersion.v0_9,
  }) : url = url ?? Uri.parse('http://localhost:8080');

  @override
  late a2a.A2AClient client = FakeA2AClient();

  @override
  String? taskId;

  @override
  String? get contextId => 'test-context-id';

  @override
  Stream<genui.A2uiMessage> get stream => const Stream.empty();

  @override
  Stream<Object> get errorStream => _errorStreamController.stream;
  final StreamController<Object> _errorStreamController =
      StreamController<Object>.broadcast();

  // Helper method for tests to inject errors
  void addError(Object error) {
    _errorStreamController.add(error);
  }

  genui.UserMessage? lastConnectAndSendChatMessage;
  genui.A2UiClientCapabilities? lastClientCapabilities;

  Future<String?> Function(
    genui.UserMessage, {
    genui.A2UiClientCapabilities? clientCapabilities,
  })?
  connectAndSendHandler;

  Future<void> Function(genui.UiEvent)? sendEventHandler;

  @override
  Future<AgentCard> getAgentCard() async {
    return AgentCard(name: 'Fake', description: 'desc', version: '1.0');
  }

  @override
  Future<String?> connectAndSend(
    genui.UserMessage message, {
    genui.A2UiClientCapabilities? clientCapabilities,
  }) async {
    lastConnectAndSendChatMessage = message;
    lastClientCapabilities = clientCapabilities;
    if (connectAndSendHandler != null) {
      return connectAndSendHandler!(
        message,
        clientCapabilities: clientCapabilities,
      );
    }
    return null;
  }

  @override
  Future<void> sendEvent(genui.UiEvent event) async {
    if (sendEventHandler != null) {
      return sendEventHandler!(event);
    }
  }

  @override
  void processA2uiMessages(Map<String, Object?> data) {
    // no-op for fake
  }

  @override
  void dispose() {
    _errorStreamController.close();
  }
}
