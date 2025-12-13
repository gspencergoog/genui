// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart' hide TextPart;
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart' hide Part;

import 'firebase_ai_content_generator_v0_8.dart';
import 'firebase_ai_content_generator_v0_9.dart';
import 'gemini_generative_model.dart';
// ignore: implementation_imports

/// A factory for creating a [GeminiGenerativeModelInterface].
///
/// This is used to allow for custom model creation, for example, for testing.
typedef GenerativeModelFactory =
    GeminiGenerativeModelInterface Function({
      required FirebaseAiContentGenerator configuration,
      Content? systemInstruction,
      List<Tool>? tools,
      ToolConfig? toolConfig,
    });

/// A [ContentGenerator] that uses the Firebase AI API to generate content.
///
/// This generator utilizes a [GeminiGenerativeModelInterface] to interact with
/// the Firebase AI API. The actual model instance is created by the
/// modelCreator function, which defaults to
/// [FirebaseAiContentGenerator.defaultGenerativeModelFactory].
abstract class FirebaseAiContentGenerator implements ContentGenerator {
  /// Creates a [FirebaseAiContentGenerator] instance with specified
  /// configurations.
  factory FirebaseAiContentGenerator({
    required Catalog catalog,
    String? systemInstruction,
    GenerativeModelFactory modelCreator = defaultGenerativeModelFactory,
    List<AiTool> additionalTools = const [],
    A2uiProtocolVersion protocolVersion = A2uiProtocolVersion.v0_8,
  }) {
    if (protocolVersion == A2uiProtocolVersion.v0_9) {
      return FirebaseAiContentGeneratorV09(
        catalog: catalog,
        systemInstruction: systemInstruction,
        modelCreator: modelCreator,
        additionalTools: additionalTools,
        protocolVersion: protocolVersion,
      );
    } else {
      return FirebaseAiContentGeneratorV08(
        catalog: catalog,
        systemInstruction: systemInstruction,
        modelCreator: modelCreator,
        additionalTools: additionalTools,
      );
    }
  }

  /// The version of the A2UI protocol to use.
  A2uiProtocolVersion get protocolVersion;

  /// The catalog of UI components available to the AI.
  Catalog get catalog;

  /// The system instruction to use for the AI model.
  String? get systemInstruction;

  /// Additional tools to make available to the AI model.
  List<AiTool> get additionalTools;

  /// The total number of input tokens used by this client.
  int get inputTokenUsage;

  /// The total number of output tokens used by this client
  int get outputTokenUsage;

  @override
  Stream<A2uiMessage> get a2uiMessageStream;

  @override
  Stream<String> get textResponseStream;

  @override
  Stream<ContentGeneratorError> get errorStream;

  @override
  ValueListenable<bool> get isProcessing;

  @override
  void dispose();

  @override
  Future<void> sendRequest(
    ChatMessage message, {
    Iterable<ChatMessage>? history,
    A2UiClientCapabilities? clientCapabilities,
  });

  /// The default factory function for creating a [GenerativeModel].
  ///
  /// This function instantiates a standard [GenerativeModel] using the `model`
  /// from the provided [FirebaseAiContentGenerator] `configuration`.
  static GeminiGenerativeModelInterface defaultGenerativeModelFactory({
    required FirebaseAiContentGenerator configuration,
    Content? systemInstruction,
    List<Tool>? tools,
    ToolConfig? toolConfig,
  }) {
    return GeminiGenerativeModel(
      FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash',
        systemInstruction: systemInstruction,
        tools: tools,
        toolConfig: toolConfig,
      ),
    );
  }
}
