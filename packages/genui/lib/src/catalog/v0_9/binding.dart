// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../../core/data_binder.dart';
import '../../model/data_model.dart';
import '../../primitives/simple_items.dart';

/// Data binder for the v0.9 protocol.
///
/// This implementation supports direct primitive values or objects with a
/// `path` key. It does not look for `literalString`, `literalBoolean`, etc.
class V09DataBinder implements DataBinder {
  final DataContext _dataContext;

  V09DataBinder(this._dataContext);

  @override
  DataContext get dataContext => _dataContext;

  @override
  ValueNotifier<String?> subscribeToString(Object? ref) {
    return _subscribeToValue<String>(ref);
  }

  @override
  ValueNotifier<bool?> subscribeToBool(Object? ref) {
    return _subscribeToValue<bool>(ref);
  }

  @override
  ValueNotifier<num?> subscribeToNum(Object? ref) {
    return _subscribeToValue<num>(ref);
  }

  @override
  ValueNotifier<List<Object?>?> subscribeToObjectArray(Object? ref) {
    return _subscribeToValue<List<Object?>>(ref);
  }

  @override
  String? resolveString(Object? ref) {
    if (ref == null) return null;
    if (ref is String) return ref;
    if (ref is Map && ref.containsKey('path')) {
      final Object? value = _dataContext.getValue<Object?>(
        DataPath(ref['path'] as String),
      );
      return value?.toString();
    }
    return null;
  }

  @override
  JsonMap resolveContext(Object? contextDefinitions) {
    final Map<String, Object?> contextMap =
        (contextDefinitions as Map<String, Object?>?) ?? const {};
    final resolved = <String, Object?>{};
    for (final MapEntry<String, Object?> entry in contextMap.entries) {
      final String key = entry.key;
      final Object? value = entry.value;
      if (value is Map && value.containsKey('path')) {
        resolved[key] = _dataContext.getValue(
          DataPath(value['path'] as String),
        );
      } else {
        // It's a literal value (or a map without a path, which we treat as
        // literal for now).
        resolved[key] = value;
      }
    }
    return resolved;
  }

  @override
  String? getTemplatePath(JsonMap template) {
    return template['path'] as String?;
  }

  ValueNotifier<T?> _subscribeToValue<T>(Object? ref) {
    if (ref == null) return ValueNotifier<T?>(null);
    if (ref is T) return ValueNotifier<T?>(ref as T);

    if (ref is Map && ref.containsKey('path')) {
      final path = ref['path'] as String;
      return _dataContext.subscribe<T>(DataPath(path));
    }

    return ValueNotifier<T?>(null);
  }
}
