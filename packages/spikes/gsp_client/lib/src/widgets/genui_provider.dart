// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../models/render_error.dart';
import '../models/streaming_models.dart';

/// An [InheritedWidget] that provides GSP-related data to the widget tree.
///
/// This is used to pass the [onEvent] and [onError] callbacks down to widgets
/// that need to fire events or report errors, without having to pass them
/// through many layers of widget constructors.
class GenUiProvider extends InheritedWidget {
  /// Creates a [GenUiProvider] that provides callbacks to its descendants.
  const GenUiProvider({
    super.key,
    required super.child,
    this.onEvent,
    this.onError,
  });

  /// A callback function that is invoked when an event is triggered by a
  /// widget.
  final ValueChanged<ClientRequest>? onEvent;

  /// A callback function that is invoked when a rendering error occurs.
  final ValueChanged<RenderError>? onError;

  /// Retrieves the [GenUiProvider] from the given [context].
  static GenUiProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GenUiProvider>();
  }

  @override
  bool updateShouldNotify(GenUiProvider oldWidget) {
    return onEvent != oldWidget.onEvent || onError != oldWidget.onError;
  }
}
