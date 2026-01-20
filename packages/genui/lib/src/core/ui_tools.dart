// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../model/a2ui_message.dart';
import '../model/a2ui_schemas.dart';
import '../model/catalog.dart';
import '../model/tools.dart';
import '../model/ui_models.dart';
import '../primitives/simple_items.dart';

/// An [AiTool] for adding or updating a UI surface.
///
/// This tool allows the AI to create a new UI surface or update an existing
/// one with a new set of components.
class UpdateComponentsTool extends AiTool<JsonMap> {
  /// Creates an [UpdateComponentsTool].
  UpdateComponentsTool({required this.handleMessage, required Catalog catalog})
    : super(
        name: 'updateComponents',
        description: 'Updates a surface with a new set of components.',
        parameters: A2uiSchemas.updateComponentsSchema(catalog),
      );

  /// The callback to invoke when adding or updating a surface.
  final void Function(A2uiMessage message) handleMessage;

  @override
  Future<JsonMap> invoke(JsonMap args) async {
    final surfaceId = args[surfaceIdKey] as String;
    final List<Component> components = (args['components'] as List).map((e) {
      final component = e as JsonMap;
      // In v0.9, the component object is flattened (no 'component' wrapper).
      // Component.fromJson expects the flattened map.
      return Component.fromJson(component);
    }).toList();
    handleMessage(
      UpdateComponents(surfaceId: surfaceId, components: components),
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
  DeleteSurfaceTool({required this.handleMessage})
    : super(
        name: 'deleteSurface',
        description: 'Removes a UI surface that is no longer needed.',
        parameters: A2uiSchemas.deleteSurfaceSchema(),
      );

  /// The callback to invoke when deleting a surface.
  final void Function(A2uiMessage message) handleMessage;

  @override
  Future<JsonMap> invoke(JsonMap args) async {
    final surfaceId = args[surfaceIdKey] as String;
    handleMessage(DeleteSurface(surfaceId: surfaceId));
    return {'status': 'Surface $surfaceId deleted.'};
  }
}

/// An [AiTool] for signaling the client to create a surface.
///
/// This tool allows the AI to create a new surface.
class CreateSurfaceTool extends AiTool<JsonMap> {
  /// Creates a [CreateSurfaceTool].
  CreateSurfaceTool({required this.handleMessage})
    : super(
        name: 'createSurface',
        description: 'Creates a new empty surface.',
        parameters: A2uiSchemas.createSurfaceSchema(),
      );

  /// The callback to invoke when signaling to create a surface.
  final void Function(A2uiMessage message) handleMessage;

  @override
  Future<JsonMap> invoke(JsonMap args) async {
    final surfaceId = args[surfaceIdKey] as String;
    final catalogId = args['catalogId'] as String;
    final theme = args['theme'] as JsonMap?;
    final bool attachDataModel = args['attachDataModel'] as bool? ?? false;
    handleMessage(
      CreateSurface(
        surfaceId: surfaceId,
        catalogId: catalogId,
        theme: theme,
        attachDataModel: attachDataModel,
      ),
    );
    return {'status': 'Surface $surfaceId created.'};
  }
}
