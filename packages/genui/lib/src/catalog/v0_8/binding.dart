// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../../core/data_binder.dart';
import '../../model/data_model.dart';
import '../../primitives/simple_items.dart';

/// Data binder for the v0.8 protocol.
///
/// This implementation supports `literalString`, `literalBoolean`,
/// `literalNumber`, `literalArray`, and `path` keys in the reference objects.
class V08DataBinder implements DataBinder {
  final DataContext _dataContext;

  V08DataBinder(this._dataContext);

  @override
  DataContext get dataContext => _dataContext;

  @override
  ValueNotifier<String?> subscribeToString(Object? ref) {
    if (ref is String) {
      return ValueNotifier(ref);
    } // Fallback for direct strings if any
    return _subscribeToValue<String>(ref, 'literalString');
  }

  @override
  ValueNotifier<bool?> subscribeToBool(Object? ref) {
    if (ref is bool) return ValueNotifier(ref);
    return _subscribeToValue<bool>(ref, 'literalBoolean');
  }

  @override
  ValueNotifier<num?> subscribeToNum(Object? ref) {
    if (ref is num) return ValueNotifier(ref);
    return _subscribeToValue<num>(ref, 'literalNumber');
  }

  @override
  ValueNotifier<List<Object?>?> subscribeToObjectArray(Object? ref) {
    if (ref is List) return ValueNotifier(ref.cast<Object?>());
    return _subscribeToValue<List<Object?>>(ref, 'literalArray');
  }

  @override
  String? resolveString(Object? ref) {
    if (ref == null) return null;
    if (ref is String) return ref;
    if (ref is Map) {
      if (ref.containsKey('path')) {
        final Object? value = _dataContext.getValue<Object?>(
          DataPath(ref['path'] as String),
        );
        return value?.toString();
      }
      if (ref.containsKey('literalString')) {
        return ref['literalString'] as String?;
      }
    }
    return null;
  }

  @override
  JsonMap resolveContext(Object? contextDefinitions) {
    final Map<String, Object?> definitions;
    if (contextDefinitions is List) {
      definitions = {
        for (final item in contextDefinitions)
          (item as Map)['key'] as String: item['value'],
      };
    } else {
      definitions = (contextDefinitions as Map<String, Object?>?) ?? const {};
    }

    final resolved = <String, Object?>{};
    for (final MapEntry<String, Object?> entry in definitions.entries) {
      final String key = entry.key;
      final value = entry.value as JsonMap;
      if (value.containsKey('path')) {
        resolved[key] = dataContext.getValue(DataPath(value['path'] as String));
      } else if (value.containsKey('literalString')) {
        resolved[key] = value['literalString'];
      } else if (value.containsKey('literalNumber')) {
        resolved[key] = value['literalNumber'];
      } else if (value.containsKey('literalBoolean')) {
        resolved[key] = value['literalBoolean'];
      }
    }
    return resolved;
  }

  @override
  String? getTemplatePath(JsonMap template) {
    return template['dataBinding'] as String?;
  }

  ValueNotifier<T?> _subscribeToValue<T>(Object? ref, String literalKey) {
    if (ref == null) return ValueNotifier<T?>(null);
    if (ref is T) {
      return ValueNotifier<T?>(
        ref as T?,
      ); // Should have been caught, but safe to keep
    }
    if (ref is Map) {
      // Using Map to be safe with JsonMap/Map<String, dynamic>
      final path = ref['path'] as String?;
      final Object? literal = ref[literalKey];

      if (path != null) {
        final dataPath = DataPath(path);
        // Initialize if literal provided (v0.8 behavior?)
        // widget_utilities.dart line 57 had initialization logic.
        if (literal != null) {
          _dataContext.update(dataPath, literal);
        }
        return _dataContext.subscribe<T>(dataPath);
      }
      if (literal is T) {
        return ValueNotifier<T?>(literal as T?);
      }
    }

    return ValueNotifier<T?>(null);
  }
}
