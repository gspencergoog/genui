// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:genui_a2ui/src/a2a/a2a.dart' as a2a;
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui_a2ui/genui_a2ui.dart';

import 'fakes.dart';

void main() {
  group('A2uiContentGenerator', () {
    late A2uiContentGenerator contentGenerator;
    late FakeA2uiAgentConnector fakeConnector;
    late FakeA2AClient fakeA2AClient;

    for (final A2uiProtocolVersion version in A2uiProtocolVersion.values) {
      group('with $version', () {
        setUp(() {
          fakeA2AClient = FakeA2AClient();
          fakeA2AClient.agentCard = const a2a.AgentCard(
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
          fakeConnector = FakeA2uiAgentConnector();
          // mocking setup if needed, usually we use dependency injection or pass it in constructor
          // A2uiContentGenerator takes a connector.

          // We need to implement `errorStream` on fakeConnector because usage depends on it.
          // FakeA2uiAgentConnector in fakes.dart returns const Stream.empty().
          // If we want to test errorStream updates, we need a controller.
        });

        tearDown(() {
          contentGenerator.dispose();
          // fakeConnector.dispose(); // Mock doesn't need dispose unless we implemented it with resources
        });

        test('sendRequest updates isProcessing', () async {
          fakeConnector = FakeA2uiAgentConnector();
          contentGenerator = A2uiContentGenerator(
            serverUrl: Uri.parse('http://fake.url'),
            connector: fakeConnector,
          );

          // Setup handler
          fakeConnector.connectAndSendHandler =
              (msg, {clientCapabilities}) async {
                // Simulate delay
                await Future.delayed(const Duration(milliseconds: 10));
                return 'Response';
              };

          final userMessage = UserMessage([const TextPart('Hello')]);

          expect(contentGenerator.isProcessing.value, isFalse);
          final Future<void> future = contentGenerator.sendRequest(
            userMessage,
            clientCapabilities: const A2UiClientCapabilities(
              supportedCatalogIds: ['test_catalog'],
            ),
          );
          expect(contentGenerator.isProcessing.value, isTrue);

          await future;

          expect(contentGenerator.isProcessing.value, isFalse);
        });

        test('sendRequest passes clientCapabilities to connector', () async {
          fakeConnector = FakeA2uiAgentConnector();
          contentGenerator = A2uiContentGenerator(
            serverUrl: Uri.parse('http://fake.url'),
            connector: fakeConnector,
          );

          UserMessage? capturedMessage;
          A2UiClientCapabilities? capturedCapabilities;

          fakeConnector.connectAndSendHandler =
              (msg, {clientCapabilities}) async {
                capturedMessage = msg;
                capturedCapabilities = clientCapabilities;
                return 'Response';
              };

          final userMessage = UserMessage([const TextPart('Test')]);
          const capabilities = A2UiClientCapabilities(
            supportedCatalogIds: ['test_catalog'],
          );

          await contentGenerator.sendRequest(
            userMessage,
            clientCapabilities: capabilities,
          );

          expect(capturedCapabilities, capabilities);
          expect(capturedMessage, userMessage);
        });

        test('sendRequest adds response to textResponseStream', () async {
          fakeConnector = FakeA2uiAgentConnector();
          contentGenerator = A2uiContentGenerator(
            serverUrl: Uri.parse('http://fake.url'),
            connector: fakeConnector,
          );

          fakeConnector.connectAndSendHandler =
              (msg, {clientCapabilities}) async {
                return 'Fake AI Response';
              };

          final userMessage = UserMessage([const TextPart('Test')]);
          final completer = Completer<String>();
          contentGenerator.textResponseStream.listen(completer.complete);

          await contentGenerator.sendRequest(
            userMessage,
            clientCapabilities: const A2UiClientCapabilities(
              supportedCatalogIds: ['test_catalog'],
            ),
          );

          expect(await completer.future, 'Fake AI Response');
        });

        test('errorStream forwards errors from connector', () async {
          // To test error forwarding, we need a way to emit errors from connector.errorStream.
          // The current FakeA2uiAgentConnector returns Stream.empty().
          // We must subclass or use a different mock setup that allows controlling the stream.

          final controller = StreamController<Object>();

          // Create a custom mock/fake that uses this controller
          final customFake = FakeA2uiAgentConnectorWithStream(
            controller.stream,
          );

          contentGenerator = A2uiContentGenerator(
            serverUrl: Uri.parse('http://fake.url'),
            connector: customFake,
          );

          final completer = Completer<ContentGeneratorError>();
          contentGenerator.errorStream.listen(completer.complete);

          final testError = Exception('Test Error');
          controller.add(testError);

          final ContentGeneratorError capturedError = await completer.future;
          expect(capturedError.error, testError);

          await controller.close();
        });
      });
    }
  });
}

class FakeA2uiAgentConnectorWithStream extends FakeA2uiAgentConnector {
  final Stream<Object> _customErrorStream;
  FakeA2uiAgentConnectorWithStream(this._customErrorStream);

  @override
  Stream<Object> get errorStream => _customErrorStream;

  // We also need to override dispose to avoid closing the controller if we owned it,
  // but here we just injected the stream.
  @override
  void dispose() {}
}
