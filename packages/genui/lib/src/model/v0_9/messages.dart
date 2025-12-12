// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../primitives/simple_items.dart';
import '../a2ui_message.dart';
import '../a2ui_protocol.dart';
import '../ui_models.dart';

/// An A2UI message that updates a surface with new components (V0.9).
final class UpdateComponents extends A2uiMessage {
  /// Creates a [UpdateComponents] message.
  const UpdateComponents({required this.surfaceId, required this.components})
    : super(A2uiProtocolVersion.v0_9);

  /// Creates a [UpdateComponents] message from a JSON map.
  factory UpdateComponents.fromJson(JsonMap json) {
    return UpdateComponents(
      surfaceId: json[surfaceIdKey] as String,
      components: (json['components'] as List<Object?>)
          .map(
            (e) => Component.fromJson(
              e as JsonMap,
              version: A2uiProtocolVersion.v0_9,
            ),
          )
          .toList(),
    );
  }

  /// The ID of the surface that this message applies to.
  final String surfaceId;

  /// The list of components to add or update.
  final List<Component> components;

  /// Converts this object to a JSON representation.
  JsonMap toJson() {
    return {
      surfaceIdKey: surfaceId,
      'components': components.map((c) => c.toJson()).toList(),
    };
  }
}

/// An A2UI message that updates the data model (V0.9).
final class UpdateDataModel extends A2uiMessage {
  /// Creates a [UpdateDataModel] message.
  const UpdateDataModel({
    required this.surfaceId,
    this.path,
    this.op = 'replace',
    required this.value,
  }) : super(A2uiProtocolVersion.v0_9);

  /// Creates a [UpdateDataModel] message from a JSON map.
  factory UpdateDataModel.fromJson(JsonMap json) {
    return UpdateDataModel(
      surfaceId: json[surfaceIdKey] as String,
      path: json['path'] as String?,
      op: json['op'] as String? ?? 'replace',
      value: json['value'] as Object,
    );
  }

  /// The ID of the surface that this message applies to.
  final String surfaceId;

  /// The path in the data model to update.
  final String? path;

  /// The operation to perform (add, replace, remove).
  final String op;

  /// The new value to write to the data model.
  final Object value;
}

/// An A2UI message that signals the client to begin rendering (V0.9).
final class CreateSurface extends A2uiMessage {
  /// Creates a [CreateSurface] message.
  const CreateSurface({required this.surfaceId, required this.catalogId})
    : super(A2uiProtocolVersion.v0_9);

  /// Creates a [CreateSurface] message from a JSON map.
  factory CreateSurface.fromJson(JsonMap json) {
    return CreateSurface(
      surfaceId: json[surfaceIdKey] as String,
      catalogId: json['catalogId'] as String,
    );
  }

  /// The ID of the surface that this message applies to.
  final String surfaceId;

  /// The catalog ID used for this surface.
  final String catalogId;
}

/// An A2UI message that deletes a surface (V0.9).
final class DeleteSurface extends A2uiMessage {
  /// Creates a [DeleteSurface] message.
  const DeleteSurface({required this.surfaceId})
    : super(A2uiProtocolVersion.v0_9);

  /// Creates a [DeleteSurface] message from a JSON map.
  factory DeleteSurface.fromJson(JsonMap json) {
    return DeleteSurface(surfaceId: json[surfaceIdKey] as String);
  }

  /// The ID of the surface that this message applies to.
  final String surfaceId;
}

/// An A2UI message that reports an error (V0.9).
final class ErrorMessage extends A2uiMessage {
  /// Creates a [ErrorMessage] message.
  const ErrorMessage({
    required this.code,
    required this.message,
    this.surfaceId,
    this.path,
  }) : super(A2uiProtocolVersion.v0_9);

  /// Creates a [ErrorMessage] message from a JSON map.
  factory ErrorMessage.fromJson(JsonMap json) {
    return ErrorMessage(
      code: json['code'] as String,
      message: json['message'] as String,
      surfaceId: json['surfaceId'] as String?,
      path: json['path'] as String?,
    );
  }

  /// The error code.
  final String code;

  /// The error message.
  final String message;

  /// The ID of the surface that this error applies to.
  final String? surfaceId;

  /// The path in the data model that this error applies to.
  final String? path;
}
