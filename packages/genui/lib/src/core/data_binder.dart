// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../../genui.dart' show DataContext;
import '../model/data_model.dart' show DataContext;
import '../primitives/simple_items.dart';

/// An interface for binding data from a data source to UI components.
///
/// Implementations of this interface handle the specifics of how data is
/// accessed and resolved, which may vary between different protocol versions
/// (e.g., v0.8 vs v0.9).
abstract interface class DataBinder {
  /// The [DataContext] associated with this binder.
  DataContext get dataContext;

  /// Subscribes to a string value.
  ///
  /// The [ref] can be a literal value or a reference/path to a value in the
  /// data source.
  ValueNotifier<String?> subscribeToString(Object? ref);

  /// Subscribes to a boolean value.
  ValueNotifier<bool?> subscribeToBool(Object? ref);

  /// Subscribes to a numeric value.
  ValueNotifier<num?> subscribeToNum(Object? ref);

  /// Subscribes to a list of objects.
  ValueNotifier<List<Object?>?> subscribeToObjectArray(Object? ref);

  /// Resolves a string value immediately.
  String? resolveString(Object? ref);

  /// Resolves a context map for actions.
  JsonMap resolveContext(Object? contextDefinitions);

  /// Gets the data path from a template object.
  ///
  /// This handles differences in keys (e.g. 'dataBinding' vs 'path') between
  /// protocol versions.
  String? getTemplatePath(JsonMap template);
}
