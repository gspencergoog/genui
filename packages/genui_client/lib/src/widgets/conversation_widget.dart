// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../genui_surface.dart';
import '../model/chat_message.dart';
import '../ui_agent.dart';
import 'chat_primitives.dart';

/// A builder for a user prompt widget.
typedef UserPromptBuilder = Widget Function(
    BuildContext context, UserMessage message);

/// A widget that displays a conversation from a [UiAgent].
class ConversationWidget extends StatelessWidget {
  /// Creates a new [ConversationWidget].
  const ConversationWidget({
    super.key,
    required this.agent,
    this.userPromptBuilder,
    this.showInternalMessages = false,
  });

  /// The [UiAgent] that this widget is connected to.
  final UiAgent agent;

  /// A builder for user prompt widgets.
  final UserPromptBuilder? userPromptBuilder;

  /// Whether to show internal messages in the conversation.
  final bool showInternalMessages;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ChatMessage>>(
      valueListenable: agent.conversation,
      builder: (context, messages, child) {
        final renderedMessages = messages.where((message) {
          if (showInternalMessages) {
            return true;
          }
          return message is! InternalMessage && message is! ToolResponseMessage;
        }).toList();
        return ListView.builder(
          itemCount: renderedMessages.length,
          itemBuilder: (context, index) {
            final message = renderedMessages[index];
            switch (message) {
              case UserMessage():
                return userPromptBuilder != null
                    ? userPromptBuilder!(context, message)
                    : ChatMessageWidget(
                        text: message.parts
                            .whereType<TextPart>()
                            .map((part) => part.text)
                            .join('\n'),
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
                    builder: agent.builder,
                    surfaceId: message.surfaceId,
                    onEvent: (event) {},
                  ),
                );
              case InternalMessage():
                return InternalMessageWidget(content: message.text);
              case ToolResponseMessage():
                return InternalMessageWidget(
                    content: message.results.toString());
            }
          },
        );
      },
    );
  }
}
