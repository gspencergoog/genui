// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../primitives/simple_items.dart';
import '../a2ui_message.dart';
import '../ui_models.dart';

/// An A2UI message that updates a surface with new components (V0.8).
final class SurfaceUpdate implements A2uiMessage {
  /// Creates a [SurfaceUpdate] message.
  const SurfaceUpdate({required this.surfaceId, required this.components});

  /// Creates a [SurfaceUpdate] message from a JSON map.
  factory SurfaceUpdate.fromJson(JsonMap json) {
    return SurfaceUpdate(
      surfaceId: json[surfaceIdKey] as String,
      components: (json['components'] as List<Object?>)
          .map((e) => Component.fromJson(e as JsonMap))
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

/// An A2UI message that updates the data model (V0.8).
final class DataModelUpdate implements A2uiMessage {
  /// Creates a [DataModelUpdate] message.
  const DataModelUpdate({
    required this.surfaceId,
    this.path,
    required this.contents,
  });

  /// Creates a [DataModelUpdate] message from a JSON map.
  factory DataModelUpdate.fromJson(JsonMap json) {
    return DataModelUpdate(
      surfaceId: json[surfaceIdKey] as String,
      path: json['path'] as String?,
      contents: json['contents'] as Object,
    );
  }

  /// The ID of the surface that this message applies to.
  final String surfaceId;

  /// The path in the data model to update.
  final String? path;

  /// The new contents to write to the data model.
  final Object contents;
}

/// An A2UI message that signals the client to begin rendering (V0.8).
final class BeginRendering implements A2uiMessage {
  /// Creates a [BeginRendering] message.
  const BeginRendering({
    required this.surfaceId,
    required this.root,
    this.styles,
    this.catalogId,
  });

  /// Creates a [BeginRendering] message from a JSON map.
  factory BeginRendering.fromJson(JsonMap json) {
    return BeginRendering(
      surfaceId: json[surfaceIdKey] as String,
      root: json['root'] as String,
      styles: json['styles'] as JsonMap?,
      catalogId: json['catalogId'] as String?,
    );
  }

  /// The ID of the surface that this message applies to.
  final String surfaceId;

  /// The ID of the root component.
  final String root;

  /// The styles to apply to the UI.
  final JsonMap? styles;

  /// The ID of the catalog to use for rendering this surface.
  final String? catalogId;
}

/// An A2UI message that deletes a surface (V0.8).
final class DeleteSurface implements A2uiMessage {
  /// Creates a [DeleteSurface] message.
  const DeleteSurface({required this.surfaceId});

  /// Creates a [DeleteSurface] message from a JSON map.
  factory DeleteSurface.fromJson(JsonMap json) {
    return DeleteSurface(surfaceId: json[surfaceIdKey] as String);
  }

  /// The ID of the surface that this message applies to.
  final String surfaceId;
}

/// An A2UI message that reports an error (V0.8).
final class ErrorMessage implements A2uiMessage {
  /// Creates a [ErrorMessage] message.
  const ErrorMessage({
    required this.code,
    required this.message,
    this.surfaceId,
    this.path,
  });

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
