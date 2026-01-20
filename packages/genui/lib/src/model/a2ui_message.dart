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

  /// The ID of the surface that this message applies to.
  String get surfaceId;

  /// Creates an [A2uiMessage] from a JSON map.
  factory A2uiMessage.fromJson(JsonMap json) {
    if (json.containsKey('updateComponents')) {
      return UpdateComponents.fromJson(json['updateComponents'] as JsonMap);
    }
    if (json.containsKey('updateDataModel')) {
      return UpdateDataModel.fromJson(json['updateDataModel'] as JsonMap);
    }
    if (json.containsKey('createSurface')) {
      return CreateSurface.fromJson(json['createSurface'] as JsonMap);
    }
    if (json.containsKey('deleteSurface')) {
      return DeleteSurface.fromJson(json['deleteSurface'] as JsonMap);
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
        'deleteSurface': A2uiSchemas.deleteSurfaceSchema(),
      },
    );
  }
}

/// An A2UI message that updates a surface with new components.
final class UpdateComponents extends A2uiMessage {
  /// Creates an [UpdateComponents] message.
  const UpdateComponents({required this.surfaceId, required this.components});

  /// Creates an [UpdateComponents] message from a JSON map.
  factory UpdateComponents.fromJson(JsonMap json) {
    return UpdateComponents(
      surfaceId: json[surfaceIdKey] as String,
      components: (json['components'] as List<Object?>)
          .map((e) => Component.fromJson(e as JsonMap))
          .toList(),
    );
  }

  /// The ID of the surface that this message applies to.
  @override
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

/// An A2UI message that updates the data model.
final class UpdateDataModel extends A2uiMessage {
  /// Creates an [UpdateDataModel] message.
  const UpdateDataModel({
    required this.surfaceId,
    this.path,
    required this.value,
  });

  /// Creates an [UpdateDataModel] message from a JSON map.
  factory UpdateDataModel.fromJson(JsonMap json) {
    return UpdateDataModel(
      surfaceId: json[surfaceIdKey] as String,
      path: json['path'] as String?,
      value: json['value'] as Object,
    );
  }

  /// The ID of the surface that this message applies to.
  @override
  final String surfaceId;

  /// The path in the data model to update.
  final String? path;

  /// The new value to write to the data model.
  final Object value;
}

/// An A2UI message that signals the client to create a surface.
final class CreateSurface extends A2uiMessage {
  /// Creates a [CreateSurface] message.
  const CreateSurface({
    required this.surfaceId,
    required this.catalogId,
    this.theme,
    this.attachDataModel = false,
  });

  /// Creates a [CreateSurface] message from a JSON map.
  factory CreateSurface.fromJson(JsonMap json) {
    return CreateSurface(
      surfaceId: json[surfaceIdKey] as String,
      catalogId: json['catalogId'] as String,
      theme: json['theme'] as JsonMap?,
      attachDataModel: json['attachDataModel'] as bool? ?? false,
    );
  }

  /// The ID of the surface that this message applies to.
  @override
  final String surfaceId;

  /// The ID of the catalog to use for rendering this surface.
  final String catalogId;

  /// The theme to apply to the UI.
  final JsonMap? theme;

  /// Whether to attach the data model to client messages.
  final bool attachDataModel;
}

/// An A2UI message that deletes a surface.
final class DeleteSurface extends A2uiMessage {
  /// Creates a [DeleteSurface] message.
  const DeleteSurface({required this.surfaceId});

  /// Creates a [DeleteSurface] message from a JSON map.
  factory DeleteSurface.fromJson(JsonMap json) {
    return DeleteSurface(surfaceId: json[surfaceIdKey] as String);
  }

  /// The ID of the surface that this message applies to.
  @override
  final String surfaceId;
}
