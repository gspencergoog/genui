// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../model/catalog.dart';
import '../model/data_model.dart';
import '../model/ui_models.dart';

/// A sealed class representing an update to the UI managed by
/// [GenUiHost].
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

  /// Emits a [GenUiUpdate] to the surface updates stream.
  void emitUpdate(GenUiUpdate update);

  /// Removes the surface with the given [surfaceId] and cleans up resources.
  void removeSurface(String surfaceId);
}
