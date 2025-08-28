// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../genui_surface.dart';
import '../model/chat_box.dart';
import '../model/chat_message.dart';
import '../ui_agent.dart';
import 'chat_primitives.dart';

/// A widget that provides a chat interface for interacting with a [UiAgent].
class GenUiChat extends StatefulWidget {
  /// Creates a new [GenUiChat] widget.
  const GenUiChat({
    super.key,
    required this.agent,
    required this.onEvent,
    this.showInternalMessages = false,
    this.chatBoxBuilder = defaultChatBoxBuilder,
  });

  /// The [UiAgent] that this chat widget is connected to.
  final UiAgent agent;

  /// A builder for the chat box widget.
  final ChatBoxBuilder chatBoxBuilder;

  /// A callback for when a user interacts with a widget in the chat.
  final UiEventCallback onEvent;

  /// Whether to show internal messages in the chat.
  final bool showInternalMessages;

  @override
  State<GenUiChat> createState() => _GenUiChatState();
}

class _GenUiChatState extends State<GenUiChat> {
  late final ChatBoxController _chatController;

  @override
  void initState() {
    super.initState();
    _chatController = ChatBoxController(_onChatInput);
    widget.agent.isProcessing.addListener(_onProcessingChanged);
  }

  void _onProcessingChanged() {
    if (widget.agent.isProcessing.value) {
      _chatController.setRequested();
    } else {
      _chatController.setResponded();
    }
  }

  void _onChatInput(String input) {
    widget.agent.sendRequest(UserMessage.text(input));
  }

  @override
  void dispose() {
    widget.agent.isProcessing.removeListener(_onProcessingChanged);
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ChatMessage>>(
      valueListenable: widget.agent.conversation,
      builder: (context, messages, child) {
        final filteredMessages = messages.where((message) {
          if (widget.showInternalMessages) {
            return true;
          }
          return message is! InternalMessage && message is! ToolResponseMessage;
        }).toList();

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: ListView.builder(
                // Reverse the list to show the latest message at the bottom.
                reverse: true,
                itemCount: filteredMessages.length,
                itemBuilder: (context, index) {
                  index = filteredMessages.length - 1 - index; // Reverse index
                  final message = filteredMessages[index];
                  switch (message) {
                    case UserMessage():
                      final text = message.parts
                          .whereType<TextPart>()
                          .map<String>((part) => part.text)
                          .join('\n');
                      if (text.trim().isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return ChatMessageWidget(
                        text: text,
                        icon: Icons.person,
                        alignment: MainAxisAlignment.end,
                      );
                    case AiTextMessage():
                      final text = message.parts
                          .whereType<TextPart>()
                          .map((part) => part.text)
                          .join('\n');
                      if (text.trim().isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return ChatMessageWidget(
                        text: text,
                        icon: Icons.smart_toy_outlined,
                        alignment: MainAxisAlignment.start,
                      );
                    case AiUiMessage():
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GenUiSurface(
                          key: message.uiKey,
                          builder: widget.agent.builder,
                          surfaceId: message.surfaceId,
                          onEvent: widget.onEvent,
                        ),
                      );
                    case InternalMessage():
                      return const SizedBox.shrink();
                    case ToolResponseMessage():
                      return const SizedBox.shrink();
                  }
                },
              ),
            ),
            const SizedBox(height: 8.0),
            widget.chatBoxBuilder(_chatController, context),
          ],
        );
      },
    );
  }
}
