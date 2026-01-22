// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../model/data_model.dart';
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
  /// Subscribes to a dynamic value (v0.9).
  ///
  /// [definition] can be:
  /// - A literal value (String, num, bool).
  /// - A map with 'path' key.
  /// - A map with 'call' key (function).
  ///
  /// If the definition points to a path, this returns a notifier that updates
  /// when the data at that path changes.
  /// Otherwise, it returns a static notifier with the resolved value.
  ValueNotifier<T?> subscribeToDynamicValue<T>(Object? definition) {
    if (definition == null) return ValueNotifier<T?>(null);

    // 1. Handle explicit path objects
    if (definition is Map && definition.containsKey('path')) {
      final path = definition['path'] as String?;
      if (path != null) {
        return subscribe<T>(DataPath(path));
      }
    }

    // 2. Handle function calls or complex objects (resolved once for now)
    // TODO: Implement reactive function calls if they depend on data.
    if (definition is Map && definition.containsKey('call')) {
      // Ideally we'd analyze dependencies. For now, static resolution.
      if (T == String) {
        return ValueNotifier<T?>(resolveDynamicString(definition) as T?);
      }
      if (T == num) {
        return ValueNotifier<T?>(resolveDynamicNumber(definition) as T?);
      }
      if (T == bool) {
        return ValueNotifier<T?>(resolveDynamicBool(definition) as T?);
      }
    }

    // 3. Handle literals (including interpolated strings resolved ONCE)
    if (definition is String && T == String) {
      return ValueNotifier<T?>(resolveDynamicString(definition) as T?);
    }

    // Fallback for simple literals
    if (definition is T) {
      return ValueNotifier<T?>(definition as T);
    }

    // Try resolving generally if T allows
    if (T == String) {
      return ValueNotifier<T?>(resolveDynamicString(definition) as T?);
    }
    if (T == num) {
      return ValueNotifier<T?>(resolveDynamicNumber(definition) as T?);
    }
    if (T == bool) {
      return ValueNotifier<T?>(resolveDynamicBool(definition) as T?);
    }

    return ValueNotifier<T?>(definition as T?);
  }

  /// Subscribes to a dynamic string.
  ValueNotifier<String?> subscribeToString(Object? definition) {
    return subscribeToDynamicValue<String>(definition);
  }

  /// Subscribes to a dynamic boolean.
  ValueNotifier<bool?> subscribeToBool(Object? definition) {
    return subscribeToDynamicValue<bool>(definition);
  }

  /// Subscribes to a dynamic object/list.
  ValueNotifier<List<Object?>?> subscribeToObjectArray(Object? definition) {
    return subscribeToDynamicValue<List<Object?>>(definition);
  }
}

/// Resolves a context map definition against a [DataContext].
JsonMap resolveContext(DataContext dataContext, JsonMap contextDefinitions) {
  final resolved = <String, Object?>{};
  for (final MapEntry<String, Object?> entry in contextDefinitions.entries) {
    final String key = entry.key;
    final Object? valueDef = entry.value;
    // We assume the value definition is a DynamicValue (string/num/bool/etc.)
    // We try to resolve it as best we can.
    if (valueDef is String) {
      resolved[key] = dataContext.resolveDynamicString(valueDef);
    } else if (valueDef is num) {
      resolved[key] = dataContext.resolveDynamicNumber(valueDef);
    } else if (valueDef is bool) {
      resolved[key] = dataContext.resolveDynamicBool(valueDef);
    } else if (valueDef is Map) {
      // Could be complex object or path reference.
      // Easiest is to try resolving as string if it looks like one, or just
      // pass through?
      // Check if it has 'path' or 'call', if so, assume it might be any type.
      // v0.9 "context" values are "any".
      // Let's try to resolve dynamic string first, if not null use it?
      // Or strict check?
      if (valueDef.containsKey('path') || valueDef.containsKey('call')) {
        // Resolve generically? DataContext doesn't expose generic resolve yet
        // easily without type.
        // Let's assume String for now as that's most common in context, or just
        // raw value if resolve fails?
        // Actually `resolveDynamicString` handles path/call.
        final String? resolvedVal = dataContext.resolveDynamicString(valueDef);
        if (resolvedVal != null) {
          resolved[key] = resolvedVal;
        } else {
          // Maybe it was a number?
          final num? resolvedNum = dataContext.resolveDynamicNumber(valueDef);
          if (resolvedNum != null) {
            resolved[key] = resolvedNum;
          } else {
            // Boolean?
            final bool? resolvedBool = dataContext.resolveDynamicBool(valueDef);
            if (resolvedBool != null) {
              resolved[key] = resolvedBool;
            } else {
              resolved[key] = valueDef; // Fallback
            }
          }
        }
      } else {
        resolved[key] = valueDef;
      }
    } else {
      resolved[key] = valueDef;
    }
  }
  return resolved;
}
