// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../model/data_model.dart';
import '../primitives/logging.dart';
import '../primitives/simple_items.dart';

/// A builder widget that simplifies handling of nullable `ValueListenable`s.
///
/// This widget listens to a `ValueListenable<T?>` and rebuilds its child
/// whenever the value changes. If the value is `null`, it returns a
/// `SizedBox.shrink()`, effectively hiding the child. If the value is not
/// `null`, it calls the `builder` function with the non-nullable value.
class OptionalValueBuilder<T> extends StatelessWidget {
  /// The `ValueListenable` to listen to.
  final ValueListenable<T?> listenable;

  /// The builder function to call when the value is not `null`.
  final Widget Function(BuildContext context, T value) builder;

  /// Creates an `OptionalValueBuilder`.
  const OptionalValueBuilder({
    super.key,
    required this.listenable,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T?>(
      valueListenable: listenable,
      builder: (context, value, _) {
        if (value == null) return const SizedBox.shrink();
        return builder(context, value);
      },
    );
  }
}

/// Extension methods for [DataContext] to simplify data binding.
extension DataContextExtensions on DataContext {
  /// Subscribes to a value, which can be a literal or a data-bound path.
  ValueNotifier<T?> subscribeToValue<T>(Object? ref, String literalKey) {
    genUiLogger.info(
      'DataContext.subscribeToValue: ref=$ref, literalKey=$literalKey',
    );
    if (ref == null) return ValueNotifier<T?>(null);
    if (ref is T) return ValueNotifier<T?>(ref as T);

    if (ref is Map<String, Object?>) {
      final path = ref['path'] as String?;
      final Object? literal = ref[literalKey];

      if (path != null) {
        final dataPath = DataPath(path);
        if (literal != null) {
          update(dataPath, literal);
        }
        return subscribe<T>(dataPath);
      }
      if (literal is T) {
        return ValueNotifier<T?>(literal as T?);
      }
    }

    return ValueNotifier<T?>(null);
  }

  /// Subscribes to a string value, which can be a literal or a data-bound path.
  ValueNotifier<String?> subscribeToString(Object? ref) {
    return subscribeToValue<String>(ref, 'literalString');
  }

  /// Subscribes to a boolean value, which can be a literal or a data-bound
  /// path.
  ValueNotifier<bool?> subscribeToBool(Object? ref) {
    return subscribeToValue<bool>(ref, 'literalBoolean');
  }

  /// Subscribes to a list of objects, which can be a literal or a data-bound
  /// path.
  ValueNotifier<List<Object?>?> subscribeToObjectArray(Object? ref) {
    return subscribeToValue<List<Object?>>(ref, 'literalArray');
  }
}

/// A function types that resolves a context map definition against a
/// [DataContext].
typedef ContextResolver =
    JsonMap Function(
      DataContext dataContext,
      Map<String, Object?> contextDefinitions,
    );

/// Resolves a string reference against a [DataContext].
String? resolveStringReference(DataContext dataContext, Object? ref) {
  if (ref == null) return null;
  if (ref is String) return ref;

  if (ref is Map<String, Object?>) {
    if (ref.containsKey('path')) {
      final Object? value = dataContext.getValue<Object?>(
        DataPath(ref['path'] as String),
      );
      return value?.toString();
    } else if (ref.containsKey('literalString')) {
      return ref['literalString'] as String?;
    }
  }
  return null;
}
