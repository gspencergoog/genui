// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';

import '../primitives/simple_items.dart';
import 'a2ui_schemas.dart';
import 'catalog.dart';
import 'tools.dart';
import 'ui_models.dart';

/// A sealed class representing a message in the A2UI stream.
sealed class A2uiMessage {
  /// Creates an [A2uiMessage].
  const A2uiMessage();

  /// Creates an [A2uiMessage] from a JSON map.
  ///
  /// This defaults to parsing as V0.9. For other versions, use
  /// [A2uiProtocol.fromVersion(version).parseJson].
  factory A2uiMessage.fromJson(JsonMap json) {
    // Default to V0.9 parsing behavior for backward compatibility of this API
    // in this branch, but ideally clients should use A2uiProtocol.
    if (json.containsKey('updateComponents')) {
      return UpdateComponents.fromJson(json['updateComponents'] as JsonMap);
    }
    if (json.containsKey('updateDataModel')) {
      return UpdateDataModel.fromJson(json['updateDataModel'] as JsonMap);
    }
    if (json.containsKey('createSurface')) {
      return CreateSurface.fromJson(json['createSurface'] as JsonMap);
    }
    // Shared messages
    if (json.containsKey('deleteSurface')) {
      return DeleteSurface.fromJson(json['deleteSurface'] as JsonMap);
    }
    if (json.containsKey('error')) {
      return ErrorMessage.fromJson(json['error'] as JsonMap);
    }
    throw ArgumentError('Unknown A2UI message type: $json');
  }

  /// Returns the JSON schema for an A2UI message.
  static Schema a2uiMessageSchema(Catalog catalog) {
    return S.object(
      title: 'A2UI Message Schema',
      description:
          """Describes a JSON payload for an A2UI (Agent to UI) message, which is used to dynamically construct and update user interfaces. A message MUST contain exactly ONE of the action properties: 'createSurface', 'updateComponents', 'updateDataModel', or 'deleteSurface'.""",
      properties: {
        'updateComponents': A2uiSchemas.updateComponentsSchema(catalog),
        'updateDataModel': A2uiSchemas.updateDataModelSchema(),
        'createSurface': A2uiSchemas.createSurfaceSchema(),
        'deleteSurface': A2uiSchemas.surfaceDeletionSchema(),
        'error': A2uiSchemas.errorSchema(),
      },
    );
  }
}

/// Abstract base class for V0.8 messages.
sealed class A2uiMessageV08 extends A2uiMessage {
  const A2uiMessageV08();
}

/// Abstract base class for V0.9 messages.
sealed class A2uiMessageV09 extends A2uiMessage {
  const A2uiMessageV09();
}

// -------------------- V0.9 Messages --------------------

/// An A2UI message that updates a surface with new components (V0.9).
final class UpdateComponents extends A2uiMessageV09 {
  /// Creates a [UpdateComponents] message.
  const UpdateComponents({required this.surfaceId, required this.components});

  /// Creates a [UpdateComponents] message from a JSON map.
  factory UpdateComponents.fromJson(JsonMap json) {
    return UpdateComponents(
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

/// An A2UI message that updates the data model (V0.9).
final class UpdateDataModel extends A2uiMessageV09 {
  /// Creates a [UpdateDataModel] message.
  const UpdateDataModel({
    required this.surfaceId,
    this.path,
    this.op = 'replace',
    required this.value,
  });

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
final class CreateSurface extends A2uiMessageV09 {
  /// Creates a [CreateSurface] message.
  const CreateSurface({required this.surfaceId, required this.catalogId});

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

// -------------------- V0.8 Messages --------------------

/// An A2UI message that updates a surface with new components (V0.8).
final class SurfaceUpdate extends A2uiMessageV08 {
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
final class DataModelUpdate extends A2uiMessageV08 {
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
final class BeginRendering extends A2uiMessageV08 {
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

// -------------------- Shared Messages --------------------

/// An A2UI message that deletes a surface.
///
/// This is used in both V0.8 and V0.9, though the JSON structure might vary
/// slightly, here we assume it's compatible or handled by protocol parsers.
final class DeleteSurface extends A2uiMessage {
  /// Creates a [DeleteSurface] message.
  const DeleteSurface({required this.surfaceId});

  /// Creates a [DeleteSurface] message from a JSON map.
  factory DeleteSurface.fromJson(JsonMap json) {
    return DeleteSurface(surfaceId: json[surfaceIdKey] as String);
  }

  /// The ID of the surface that this message applies to.
  final String surfaceId;
}

/// An A2UI message that reports an error.
final class ErrorMessage extends A2uiMessage {
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
