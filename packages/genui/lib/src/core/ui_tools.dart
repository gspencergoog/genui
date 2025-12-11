// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';

import '../model/a2ui_message.dart';
import '../model/catalog.dart';
import '../model/tools.dart';
import '../model/ui_models.dart';
import '../model/v0_8/messages.dart' as v0_8_messages;
import '../model/v0_8/schemas.dart' as v0_8_schemas;
import '../model/v0_9/messages.dart' as v0_9_messages;
import '../model/v0_9/schemas.dart' as v0_9_schemas;
import '../primitives/simple_items.dart';

/// An [AiTool] for adding or updating a UI surface.
///
/// This tool allows the AI to create a new UI surface or update an existing
/// one with a new definition.
class UpdateComponentsTool extends AiTool<JsonMap> {
  /// Creates an [UpdateComponentsTool].
  UpdateComponentsTool({required this.handleMessage, required Catalog catalog})
    : super(
        name: 'updateComponents',
        description: 'Update the UI components on a surface.',
        parameters: v0_9_schemas.Schemas.updateComponentsSchema(catalog),
      );

  /// The callback to invoke when adding or updating a surface.
  final void Function(A2uiMessage message) handleMessage;

  @override
  Future<JsonMap> invoke(JsonMap args) async {
    final surfaceId = args[surfaceIdKey] as String;
    final List<Component> components = (args['components'] as List).map((e) {
      return Component.fromJson(e as JsonMap);
    }).toList();
    handleMessage(
      v0_9_messages.UpdateComponents(
        surfaceId: surfaceId,
        components: components,
      ),
    );
    return {
      surfaceIdKey: surfaceId,
      'status': 'UI Surface $surfaceId updated.',
    };
  }
}

/// An [AiTool] for deleting a UI surface.
///
/// This tool allows the AI to remove a UI surface that is no longer needed.
class DeleteSurfaceTool extends AiTool<JsonMap> {
  /// Creates a [DeleteSurfaceTool].
  DeleteSurfaceTool({required this.handleMessage, required this.messageFactory})
    : super(
        name: 'deleteSurface',
        description: 'Removes a UI surface that is no longer needed.',
        parameters: S.object(
          properties: {
            surfaceIdKey: S.string(
              description:
                  'The unique identifier for the UI surface to remove.',
            ),
          },
          required: [surfaceIdKey],
        ),
      );

  /// The callback to invoke when deleting a surface.
  final void Function(A2uiMessage message) handleMessage;

  /// Factory to create the version-specific `DeleteSurface`
  /// message.
  final A2uiMessage Function(String surfaceId) messageFactory;

  @override
  Future<JsonMap> invoke(JsonMap args) async {
    final surfaceId = args[surfaceIdKey] as String;
    handleMessage(messageFactory(surfaceId));
    return {'status': 'Surface $surfaceId deleted.'};
  }
}

/// An [AiTool] for signaling the client to create a surface.
///
/// This tool allows the AI to initialize a UI surface.
class CreateSurfaceTool extends AiTool<JsonMap> {
  /// Creates a [CreateSurfaceTool].
  CreateSurfaceTool({required this.handleMessage})
    : super(
        name: 'createSurface',
        description: 'Create a new surface.',
        parameters: v0_9_schemas.Schemas.createSurfaceSchema(),
      );

  /// The callback to invoke when signaling to create a surface.
  final void Function(A2uiMessage message) handleMessage;

  @override
  Future<JsonMap> invoke(JsonMap args) async {
    final surfaceId = args[surfaceIdKey] as String;
    final catalogId = args['catalogId'] as String;
    handleMessage(
      v0_9_messages.CreateSurface(surfaceId: surfaceId, catalogId: catalogId),
    );
    return {'status': 'Surface $surfaceId created.'};
  }
}

/// An [AiTool] for updating a surface with new components (V0.8).
class SurfaceUpdateTool extends AiTool<JsonMap> {
  /// Creates a [SurfaceUpdateTool].
  SurfaceUpdateTool({required this.handleMessage, required Catalog catalog})
    : super(
        name: 'surfaceUpdate',
        description: 'Update the UI components on a surface.',
        parameters: v0_8_schemas.Schemas.surfaceUpdateSchema(catalog),
      );

  /// The callback to invoke.
  final void Function(A2uiMessage message) handleMessage;

  @override
  Future<JsonMap> invoke(JsonMap args) async {
    final surfaceId = args[surfaceIdKey] as String;
    final List<Component> components = (args['components'] as List).map((e) {
      return Component.fromJson(e as JsonMap);
    }).toList();
    handleMessage(
      v0_8_messages.SurfaceUpdate(surfaceId: surfaceId, components: components),
    );
    return {
      surfaceIdKey: surfaceId,
      'status': 'UI Surface $surfaceId updated.',
    };
  }
}

/// An [AiTool] for beginning rendering of a surface (V0.8).
class BeginRenderingTool extends AiTool<JsonMap> {
  /// Creates a [BeginRenderingTool].
  BeginRenderingTool({required this.handleMessage, required this.catalogId})
    : super(
        name: 'beginRendering',
        description: 'Begin rendering a surface.',
        parameters: v0_8_schemas.Schemas.beginRenderingSchema(),
      );

  /// The callback to invoke.
  final void Function(A2uiMessage message) handleMessage;

  /// The catalog ID to use.
  final String? catalogId;

  @override
  Future<JsonMap> invoke(JsonMap args) async {
    final surfaceId = args[surfaceIdKey] as String;
    final root = args['root'] as String;
    final styles = args['styles'] as JsonMap?;
    // Note: catalogId is often implicit in V0.8 or passed in args if schema
    // supports it, explicitly passing it here if needed or using the bound one.
    // The schema has catalogId.
    final String? msgCatalogId = args['catalogId'] as String? ?? catalogId;

    handleMessage(
      v0_8_messages.BeginRendering(
        surfaceId: surfaceId,
        root: root,
        styles: styles,
        catalogId: msgCatalogId,
      ),
    );
    return {'status': 'Rendering begun for $surfaceId'};
  }
}

/// An [AiTool] for updating the data model (V0.8).
class DataModelUpdateTool extends AiTool<JsonMap> {
  /// Creates a [DataModelUpdateTool].
  DataModelUpdateTool({required this.handleMessage})
    : super(
        name: 'dataModelUpdate',
        description: 'Update the data model.',
        parameters: v0_8_schemas.Schemas.dataModelUpdateSchema(),
      );

  /// The callback to invoke.
  final void Function(A2uiMessage message) handleMessage;

  @override
  Future<JsonMap> invoke(JsonMap args) async {
    final surfaceId = args[surfaceIdKey] as String;
    final path = args['path'] as String?;
    final contents = args['contents'] as Object;

    handleMessage(
      v0_8_messages.DataModelUpdate(
        surfaceId: surfaceId,
        path: path,
        contents: contents,
      ),
    );
    return {'status': 'Data model updated for $surfaceId'};
  }
}
