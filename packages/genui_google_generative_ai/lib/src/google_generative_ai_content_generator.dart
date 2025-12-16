// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genui/genui.dart';
import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart'
    as google_ai;

import 'google_generative_ai_content_generator_v0_8.dart';
import 'google_generative_ai_content_generator_v0_9.dart';
import 'google_generative_service_interface.dart';

export 'google_generative_ai_content_generator_v0_8.dart';
export 'google_generative_ai_content_generator_v0_9.dart';

/// A factory for creating a [GoogleGenerativeServiceInterface].
///
/// This is used to allow for custom service creation, for example, for testing.
typedef GenerativeServiceFactory =
    GoogleGenerativeServiceInterface Function({
      required GoogleGenerativeAiContentGenerator configuration,
    });

/// A [ContentGenerator] that uses the Google Cloud Generative Language API to
/// generate content.
///
/// This abstract class serves as a factory for creating version-specific
/// implementations of the content generator.
abstract class GoogleGenerativeAiContentGenerator implements ContentGenerator {
  /// Creates a [GoogleGenerativeAiContentGenerator] instance.
  ///
  /// Depending on the [protocolVersion], this will return a
  /// [GoogleGenerativeAiContentGeneratorV08] or
  /// [GoogleGenerativeAiContentGeneratorV09].
  factory GoogleGenerativeAiContentGenerator({
    required Catalog catalog,
    String? systemInstruction,
    String? outputToolName,
    GenerativeServiceFactory serviceFactory = defaultGenerativeServiceFactory,
    List<AiTool> additionalTools = const [],
    String modelName = 'models/gemini-2.5-flash',
    String? apiKey,
    A2uiProtocolVersion protocolVersion = A2uiProtocolVersion.v0_8,
  }) {
    if (protocolVersion == A2uiProtocolVersion.v0_9) {
      return GoogleGenerativeAiContentGeneratorV09(
        catalog: catalog,
        systemInstruction: systemInstruction,
        serviceFactory: serviceFactory,
        additionalTools: additionalTools,
        modelName: modelName,
        apiKey: apiKey,
        protocolVersion: protocolVersion,
      );
    } else {
      return GoogleGenerativeAiContentGeneratorV08(
        catalog: catalog,
        systemInstruction: systemInstruction,
        outputToolName: outputToolName ?? 'provideFinalOutput',
        serviceFactory: serviceFactory,
        additionalTools: additionalTools,
        modelName: modelName,
        apiKey: apiKey,
      );
    }
  }

  /// The default factory function for creating a [google_ai.GenerativeService].
  static GoogleGenerativeServiceInterface defaultGenerativeServiceFactory({
    required GoogleGenerativeAiContentGenerator configuration,
  }) {
    return GoogleGenerativeServiceWrapper(
      google_ai.GenerativeService.fromApiKey(configuration.apiKey),
    );
  }

  /// The catalog of UI components available to the AI.
  Catalog get catalog;

  /// The system instruction to use for the AI model.
  String? get systemInstruction;

  /// Additional tools to make available to the AI model.
  List<AiTool> get additionalTools;

  /// The model name to use (e.g., 'models/gemini-2.5-flash').
  String get modelName;

  /// The API key to use for authentication.
  String? get apiKey;

  /// The protocol version being used.
  A2uiProtocolVersion get protocolVersion;

  /// The factory function used to create the generative service.
  GenerativeServiceFactory get serviceFactory;

  /// The total number of input tokens used by this client.
  int get inputTokenUsage;

  /// The total number of output tokens used by this client
  int get outputTokenUsage;
}
