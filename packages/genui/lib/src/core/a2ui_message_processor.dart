// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';


import '../model/a2ui_message.dart';
import '../model/catalog.dart';
import '../model/chat_message.dart';
import '../model/data_model.dart';
import '../model/ui_models.dart';
import '../primitives/logging.dart';
import '../primitives/simple_items.dart';

/// A sealed class representing an update to the UI managed by
/// [A2uiMessageProcessor].
///
/// This class has three subclasses: [SurfaceAdded], [SurfaceUpdated], and
/// [SurfaceRemoved].
sealed class GenUiUpdate {
  /// Creates a [GenUiUpdate] for the given [surfaceId].
  const GenUiUpdate(this.surfaceId);

  /// The ID of the surface that was updated.
  final String surfaceId;
}

/// Fired when a new surface is created.
class SurfaceAdded extends GenUiUpdate {
  /// Creates a [SurfaceAdded] event for the given [surfaceId] and
  /// [definition].
  const SurfaceAdded(super.surfaceId, this.definition);

  /// The definition of the new surface.
  final UiDefinition definition;
}

/// Fired when an existing surface is modified.
class SurfaceUpdated extends GenUiUpdate {
  /// Creates a [SurfaceUpdated] event for the given [surfaceId] and
  /// [definition].
  const SurfaceUpdated(super.surfaceId, this.definition);

  /// The new definition of the surface.
  final UiDefinition definition;
}

/// Fired when a surface is deleted.
class SurfaceRemoved extends GenUiUpdate {
  /// Creates a [SurfaceRemoved] event for the given [surfaceId].
  const SurfaceRemoved(super.surfaceId);
}

/// An interface for a class that hosts UI surfaces.
///
/// This is used by `GenUiSurface` to get the UI definition for a surface,
/// listen for updates, and notify the host of user interactions.
abstract interface class GenUiHost {
  /// A stream of updates for the surfaces managed by this host.
  Stream<GenUiUpdate> get surfaceUpdates;

  /// Returns a [ValueNotifier] for the surface with the given [surfaceId].
  ValueNotifier<UiDefinition?> getSurfaceNotifier(String surfaceId);

  /// The catalogs of UI components available to the AI.
  Iterable<Catalog> get catalogs;

  /// A map of data models for storing the UI state of each surface.
  Map<String, DataModel> get dataModels;

  /// The data model for storing the UI state for a given surface.
  DataModel dataModelForSurface(String surfaceId);

  /// A callback to handle an action from a surface.
  void handleUiEvent(UiEvent event);
}

/// Manages the state of all dynamic UI surfaces.
///
/// This class is the core state manager for the dynamic UI. It maintains a map
/// of all active UI "surfaces", where each surface is represented by a
/// `UiDefinition`. It provides the tools (`updateComponents`, `deleteSurface`,
/// `createSurface`) that the AI uses to manipulate the UI. It exposes a stream
/// of `GenUiUpdate` events so that the application can react to changes.
class A2uiMessageProcessor implements GenUiHost {
  /// Creates a new [A2uiMessageProcessor] with a list of supported widget
  /// catalogs.
  A2uiMessageProcessor({required this.catalogs});

  @override
  final Iterable<Catalog> catalogs;

  final _surfaces = <String, ValueNotifier<UiDefinition?>>{};
  final _surfaceUpdates = StreamController<GenUiUpdate>.broadcast();
  final _onSubmit = StreamController<UserUiInteractionMessage>.broadcast();

  final _dataModels = <String, DataModel>{};

  @override
  Map<String, DataModel> get dataModels => Map.unmodifiable(_dataModels);

  @override
  DataModel dataModelForSurface(String surfaceId) {
    return _dataModels.putIfAbsent(surfaceId, DataModel.new);
  }

  /// A map of all the surfaces managed by this manager, keyed by surface ID.
  Map<String, ValueNotifier<UiDefinition?>> get surfaces => _surfaces;

  @override
  Stream<GenUiUpdate> get surfaceUpdates => _surfaceUpdates.stream;

  /// A stream of user input messages generated from UI interactions.
  Stream<UserUiInteractionMessage> get onSubmit => _onSubmit.stream;

  @override
  void handleUiEvent(UiEvent event) {
    if (event is! UserActionEvent) {
      // Or handle other event types if necessary
      return;
    }

    final String eventJsonString = jsonEncode({'userAction': event.toMap()});
    _onSubmit.add(UserUiInteractionMessage.text(eventJsonString));
  }

  @override
  ValueNotifier<UiDefinition?> getSurfaceNotifier(String surfaceId) {
    if (!_surfaces.containsKey(surfaceId)) {
      genUiLogger.fine('Adding new surface $surfaceId');
    } else {
      genUiLogger.fine('Fetching surface notifier for $surfaceId');
    }
    return _surfaces.putIfAbsent(
      surfaceId,
      () => ValueNotifier<UiDefinition?>(null),
    );
  }

  /// Disposes of the resources used by this manager.
  void dispose() {
    _surfaceUpdates.close();
    _onSubmit.close();
    for (final ValueNotifier<UiDefinition?> notifier in _surfaces.values) {
      notifier.dispose();
    }
  }

  /// Handles an [A2uiMessage] and updates the UI accordingly.
  void handleMessage(A2uiMessage message) {
    switch (message) {
      // ---------------- V0.9 Messages ----------------
      case UpdateComponents():
        _handleUpdateComponents(message.surfaceId, message.components);
      case CreateSurface():
        _handleCreateSurface(message.surfaceId, message.catalogId);
      case UpdateDataModel():
        _handleUpdateDataModel(
          message.surfaceId,
          message.path,
          message.value,
          op: message.op,
        );

      // ---------------- V0.8 Messages ----------------
      case SurfaceUpdate():
        _handleUpdateComponents(message.surfaceId, message.components);
      case BeginRendering():
        _handleBeginRendering(
          message.surfaceId,
          message.root,
          message.styles,
          message.catalogId,
        );
      case DataModelUpdate():
        _handleUpdateDataModel(
          message.surfaceId,
          message.path,
          message.contents,
        );

      // ---------------- Shared Messages ----------------
      case SurfaceDeletion():
        final String surfaceId = message.surfaceId;
        if (_surfaces.containsKey(surfaceId)) {
          genUiLogger.info('Deleting surface $surfaceId');
          final ValueNotifier<UiDefinition?>? notifier = _surfaces.remove(
            surfaceId,
          );
          notifier?.dispose();
          _dataModels.remove(surfaceId);
          _surfaceUpdates.add(SurfaceRemoved(surfaceId));
        }
      case ErrorMessage(:final code, :final message):
        genUiLogger.severe('Received A2UI Error: $code: $message');
    }
  }

  void _handleUpdateComponents(String surfaceId, List<Component> components) {
    final ValueNotifier<UiDefinition?> notifier = getSurfaceNotifier(surfaceId);

    UiDefinition uiDefinition =
        notifier.value ?? UiDefinition(surfaceId: surfaceId);
    final Map<String, Component> newComponents = Map.of(
      uiDefinition.components,
    );
    for (final component in components) {
      newComponents[component.id] = component;
    }
    uiDefinition = uiDefinition.copyWith(components: newComponents);
    notifier.value = uiDefinition;

    // Notify UI ONLY if rendering has begun.
    // In V0.8 this is explicit via BeginRendering.
    // In V0.9 it might be implicit if 'root' exists or strictly 'CreateSurface' happened?
    // We check if rootComponentId is set (V0.8 explicit) OR if 'root' exists (V0.9 implicit convention sometimes).
    if (uiDefinition.rootComponentId != null ||
        uiDefinition.components.containsKey('root')) {
      genUiLogger.info('Updating surface $surfaceId');
      _surfaceUpdates.add(SurfaceUpdated(surfaceId, uiDefinition));
    } else {
      genUiLogger.info(
        'Caching components for surface $surfaceId (pre-rendering)',
      );
    }
  }

  void _handleCreateSurface(String surfaceId, String catalogId) {
    dataModelForSurface(surfaceId);
    final ValueNotifier<UiDefinition?> notifier = getSurfaceNotifier(surfaceId);
    final isNew = notifier.value == null;
    final UiDefinition uiDefinition =
        notifier.value ?? UiDefinition(surfaceId: surfaceId);
    final UiDefinition newUiDefinition = uiDefinition.copyWith(
      catalogId: catalogId,
    );
    notifier.value = newUiDefinition;
    genUiLogger.info('Created surface $surfaceId');
    if (isNew) {
      _surfaceUpdates.add(SurfaceAdded(surfaceId, newUiDefinition));
    } else {
      _surfaceUpdates.add(SurfaceUpdated(surfaceId, newUiDefinition));
    }
  }

  void _handleUpdateDataModel(
    String surfaceId,
    String? path,
    Object value, {
    String op = 'replace',
  }) {
    final String actualPath = path ?? '/';
    genUiLogger.info(
      'Updating data model for surface $surfaceId at path '
      '$actualPath with contents:\n'
      '${const JsonEncoder.withIndent('  ').convert(value)}',
    );
    final DataModel dataModel = dataModelForSurface(surfaceId);
    // TODO: Handle 'op' (add/replace/remove) more robustly in DataModel if needed
    dataModel.update(DataPath(actualPath), value);

    // Notify UI of an update if the surface is already rendering
    final ValueNotifier<UiDefinition?> notifier = getSurfaceNotifier(surfaceId);
    final UiDefinition? uiDefinition = notifier.value;
    // We only notify if proper structure is in place
    if (uiDefinition != null &&
        (uiDefinition.rootComponentId != null ||
            uiDefinition.components.containsKey('root'))) {
      _surfaceUpdates.add(SurfaceUpdated(surfaceId, uiDefinition));
    }
  }

  void _handleBeginRendering(
    String surfaceId,
    String root,
    JsonMap? styles,
    String? catalogId,
  ) {
    final ValueNotifier<UiDefinition?> notifier = getSurfaceNotifier(surfaceId);
    final isNew =
        notifier.value ==
        null; // Should usually be dealing with existing cached def
    UiDefinition uiDefinition =
        notifier.value ?? UiDefinition(surfaceId: surfaceId);

    // Update root and styles
    // If catalogId is provided here (V0.8 style), update it too.
    uiDefinition = uiDefinition.copyWith(
      rootComponentId: root,
      styles: styles,
      catalogId: catalogId ?? uiDefinition.catalogId,
    );
    notifier.value = uiDefinition;

    genUiLogger.info('Begin rendering surface $surfaceId with root $root');

    // Always trigger an update or add since this acts as the "show" command
    if (isNew) {
      // Unlikely in V0.8 flow as components usually come first, but possible
      _surfaceUpdates.add(SurfaceAdded(surfaceId, uiDefinition));
    } else {
      _surfaceUpdates.add(SurfaceUpdated(surfaceId, uiDefinition));
    }
  }
}
