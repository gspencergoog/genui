// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'genui_surface.dart';
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'core_catalog.dart';
import 'model/catalog.dart';
import 'model/catalog_item.dart';
import 'model/ui_models.dart';
import 'primitives/logging.dart';
import 'primitives/simple_items.dart';

/// A sealed class representing an update to the UI managed by [GenUiManager].
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

/// An interface for a class that builds UI surfaces.
///
/// This is used by [GenUiSurface] to get the UI definition for a surface and to
/// listen for updates.
abstract interface class SurfaceBuilder {
  /// A stream of updates to the UI.
  Stream<GenUiUpdate> get updates;
  /// Returns a [ValueNotifier] for the given [surfaceId].
  ///
  /// The notifier will be updated when the surface definition changes.
  ValueNotifier<UiDefinition?> surface(String surfaceId);
  /// The catalog of widgets that can be used to build the UI.
  Catalog get catalog;
  /// The store for widget values.
  WidgetValueStore get valueStore;
}

/// A class that manages the state of the UI surfaces.
///
/// This class is responsible for creating, updating, and deleting surfaces,
/// and for notifying listeners of changes.
class GenUiManager implements SurfaceBuilder {
  /// Creates a new [GenUiManager].
  ///
  /// If no [catalog] is provided, the [coreCatalog] is used.
  GenUiManager({Catalog? catalog}) : catalog = catalog ?? coreCatalog;

  final _surfaces = <String, ValueNotifier<UiDefinition?>>{};
  final _updates = StreamController<GenUiUpdate>.broadcast();

  @override
  final valueStore = WidgetValueStore();

  /// A map of all the surfaces managed by this manager.
  Map<String, ValueNotifier<UiDefinition?>> get surfaces => _surfaces;

  @override
  Stream<GenUiUpdate> get updates => _updates.stream;

  @override
  final Catalog catalog;

  @override
  ValueNotifier<UiDefinition?> surface(String surfaceId) {
    return _surfaces.putIfAbsent(surfaceId, () => ValueNotifier(null));
  }

  /// Disposes of the resources used by this manager.
  void dispose() {
    _updates.close();
    for (final notifier in _surfaces.values) {
      notifier.dispose();
    }
  }

  /// Adds or updates a surface with the given [surfaceId] and [definition].
  ///
  /// If a surface with the given ID does not exist, a new one is created.
  /// Otherwise, the existing surface is updated.
  void addOrUpdateSurface(String surfaceId, JsonMap definition) {
    final uiDefinition = UiDefinition.fromMap({
      'surfaceId': surfaceId,
      ...definition,
    });
    final notifier = surface(surfaceId); // Gets or creates the notifier.
    final isNew = notifier.value == null;
    notifier.value = uiDefinition;
    if (isNew) {
      genUiLogger.info('Adding surface $surfaceId');
      _updates.add(SurfaceAdded(surfaceId, uiDefinition));
    } else {
      genUiLogger.info('Updating surface $surfaceId');
      _updates.add(SurfaceUpdated(surfaceId, uiDefinition));
    }
  }

  /// Deletes the surface with the given [surfaceId].
  void deleteSurface(String surfaceId) {
    if (_surfaces.containsKey(surfaceId)) {
      genUiLogger.info('Deleting surface $surfaceId');
      final notifier = _surfaces.remove(surfaceId);
      notifier?.dispose();
      valueStore.delete(surfaceId);
      _updates.add(SurfaceRemoved(surfaceId));
    }
  }
}