// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart' as genui;
import 'package:genui/src/model/v0_9/messages.dart' as v0_9;
import 'package:genui_a2ui/genui_a2ui.dart';
import 'package:genui_a2ui/src/a2a/a2a.dart' as a2a;

import 'fakes.dart';

void main() {
  group('A2uiAgentConnector', () {
    late A2uiAgentConnector connector;
    late FakeA2AClient fakeClient;

    setUp(() {
      fakeClient = FakeA2AClient();
      connector = A2uiAgentConnector(
        url: Uri.parse('http://localhost:8080'),
        // In the real code we can't inject client easily if we don't
        // expose it via constructor or setter, but A2uiAgentConnector
        // has it @visibleForTesting
        protocolVersion: genui.A2uiProtocolVersion.v0_9,
      );
      // Inject fake client
      connector.client = fakeClient;
    });

    tearDown(() {
      connector.dispose();
    });

    test('getAgentCard returns correct card', () async {
      fakeClient.agentCard = const a2a.AgentCard(
        name: 'Test Agent',
        description: 'A test agent',
        version: '1.0.0',
        protocolVersion: '0.9.0',
        capabilities: a2a.AgentCapabilities(),
        defaultInputModes: ['text/plain'],
        defaultOutputModes: ['text/plain'],
        skills: [],
        url: 'http://localhost:8080',
      );

      final AgentCard agentCard = await connector.getAgentCard();

      expect(agentCard.name, 'Test Agent');
      expect(agentCard.description, 'A test agent');
      expect(agentCard.version, '1.0.0');
      expect(fakeClient.getAgentCardCalled, 1);
    });

    test('connectAndSend processes stream and returns text response', () async {
      final responses = [
        const a2a.Event.statusUpdate(
          taskId: 'task1',
          contextId: 'context1',
          status: a2a.TaskStatus(
            state: a2a.TaskState.working,
            message: a2a.Message(
              role: a2a.Role.agent,
              parts: [
                a2a.Part.data(
                  data: {
                    'updateComponents': {
                      'surfaceId': 's1',
                      'components': [
                        {
                          'id': 'c1',
                          'component': 'Column',
                          'children': <Object?>[],
                        },
                      ],
                    },
                  },
                ),
                a2a.Part.text(text: 'Hello'),
              ],
              messageId: 'msg1',
            ),
          ),
        ),
      ];
      fakeClient.messageStreamHandler = (_) => Stream.fromIterable(responses);

      final messages = <genui.A2uiMessage>[];
      connector.stream.listen(messages.add);

      final userMessage = genui.UserMessage([
        const genui.TextPart('Hi'),
        const genui.TextPart('There'),
      ]);
      final String? responseText = await connector.connectAndSend(userMessage);

      expect(responseText, 'Hello');
      expect(fakeClient.lastMessageStreamParams, isNotNull);
      final a2a.Message sentMessage = fakeClient.lastMessageStreamParams!;
      expect(sentMessage.parts.length, 2);
      expect((sentMessage.parts[0] as a2a.TextPart).text, 'Hi');
      expect((sentMessage.parts[1] as a2a.TextPart).text, 'There');
      expect(connector.taskId, 'task1');
      expect(connector.contextId, 'context1');
      expect(fakeClient.messageStreamCalled, 1);
      expect(messages.length, 1);
      expect(messages.first, isA<v0_9.UpdateComponents>());
    });

    test('sendEvent sends correct event', () async {
      connector.taskId = 'task1';
      // connector.contextId ??= 'context1'; // contextId is private setter?
      // Wait, A2uiAgentConnector has `String? _contextId`. `contextId` getter.
      // Can't set contextId directly.
      // But we can set it via receiving an event first or accessing the private field via reflection?
      // Or just assume it sends what it has.
      // The connector.contextId is read-only.
      // However, connector tracks it.
      // In this test, we might not have contextId set if we didn't receive a message.
      // But we can simulate receiving a message first to set contextId.

      // Instead, we can't easily force contextId without reflection or unsafe access,
      // or modifying the Connector to be more testable.
      // But we can just test that it sends event even if contextId is null (or whatever).

      // Actually `connectAndSend` sets `_contextId`.
      // Let's call connectAndSend first to set state?
      // Or just assume contextId is null.

      fakeClient.messageSendHandler = (message) async {
        return const a2a.Task(
          id: 'task1',
          contextId: 'context1',
          status: a2a.TaskStatus(state: a2a.TaskState.working),
        );
      };

      final event = genui.UserActionEvent(
        sourceComponentId: 'btn1',
        name: 'click',
        context: {'foo': 'bar'},
      );

      await connector.sendEvent(event);

      expect(fakeClient.lastMessageSendParams, isNotNull);
      final a2a.Message sentMessage = fakeClient.lastMessageSendParams!;
      expect(sentMessage.role, a2a.Role.user);
      expect(sentMessage.parts.length, 1);
      final dataPart = sentMessage.parts.first as a2a.DataPart;
      expect(dataPart.data.containsKey('a2uiEvent'), isTrue);

      final clientEvent = dataPart.data['a2uiEvent'] as Map<String, Object?>;
      expect(clientEvent['name'], 'click');
      expect(clientEvent['sourceComponentId'], 'btn1');
    });
  });
}
