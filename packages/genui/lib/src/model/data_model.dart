// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/functions.dart';
import '../primitives/logging.dart';
import '../primitives/simple_items.dart';

@immutable
class DataPath {
  factory DataPath(String path) {
    // Determine if absolute by checking startsWith('/') BEFORE splitting
    final bool isAbs = path.startsWith(_separator);
    final List<String> segments = path
        .split(_separator)
        .where((s) => s.isNotEmpty)
        .toList();
    return DataPath._(segments, isAbs);
  }

  const DataPath._(this.segments, this.isAbsolute);

  final List<String> segments;
  final bool isAbsolute;

  static const String _separator = '/';
  static const DataPath root = DataPath._([], true);

  String get basename => segments.isNotEmpty ? segments.last : '';

  DataPath get dirname => segments.isEmpty
      ? this
      : DataPath._(segments.sublist(0, segments.length - 1), isAbsolute);

  DataPath join(DataPath other) {
    if (other.isAbsolute) {
      return other;
    }
    return DataPath._([...segments, ...other.segments], isAbsolute);
  }

  bool startsWith(DataPath other) {
    if (other.segments.length > segments.length) {
      return false;
    }
    for (var i = 0; i < other.segments.length; i++) {
      if (segments[i] != other.segments[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  String toString() {
    final String path = segments.join(_separator);
    return isAbsolute ? '$_separator$path' : path;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataPath &&
          runtimeType == other.runtimeType &&
          isAbsolute == other.isAbsolute &&
          listEquals(segments, other.segments);

  @override
  int get hashCode => Object.hash(isAbsolute, Object.hashAll(segments));
}

/// A contextual view of the main DataModel, used by widgets to resolve
/// relative and absolute paths.
class DataContext {
  DataContext(this._dataModel, String path) : path = DataPath(path);

  DataContext._(this._dataModel, this.path);

  final DataModel _dataModel;
  final DataPath path;

  /// Subscribes to a path, resolving it against the current context.
  ValueNotifier<T?> subscribe<T>(DataPath relativeOrAbsolutePath) {
    final DataPath absolutePath = resolvePath(relativeOrAbsolutePath);
    return _dataModel.subscribe<T>(absolutePath);
  }

  /// Gets a static value, resolving the path against the current context.
  T? getValue<T>(DataPath relativeOrAbsolutePath) {
    final DataPath absolutePath = resolvePath(relativeOrAbsolutePath);
    return _dataModel.getValue<T>(absolutePath);
  }

  /// Updates the data model, resolving the path against the current context.
  void update(DataPath relativeOrAbsolutePath, Object? contents) {
    final DataPath absolutePath = resolvePath(relativeOrAbsolutePath);
    _dataModel.update(absolutePath, contents);
  }

  /// Creates a new, nested DataContext for a child widget.
  /// Used by list/template widgets for their children.
  DataContext nested(DataPath relativePath) {
    final DataPath newPath = resolvePath(relativePath);
    return DataContext._(_dataModel, newPath);
  }

  DataPath resolvePath(DataPath pathToResolve) {
    if (pathToResolve.isAbsolute) {
      return pathToResolve;
    }
    return path.join(pathToResolve);
  }

  /// Subscribes to a v0.9 DynamicString, returning a ValueNotifier.
  ///
  /// If the definition is a static string, the notifier will hold that value.
  /// If it's a path, it will subscribe to that path.
  /// Interpolation and function calls are currently evaluated once.
  ValueNotifier<String?> subscribeToString(Object? definition) {
    if (definition is String) {
      return ValueNotifier(_interpolate(definition));
    }
    if (definition is Map && definition.containsKey('path')) {
      final pathStr = definition['path'] as String;
      return subscribe<String>(DataPath(pathStr));
    }
    return ValueNotifier(resolveDynamicString(definition));
  }

  /// Subscribes to a v0.9 DynamicNumber.
  ValueNotifier<num?> subscribeToNumber(Object? definition) {
    if (definition is num) {
      return ValueNotifier(definition);
    }
    if (definition is Map && definition.containsKey('path')) {
      final pathStr = definition['path'] as String;
      return subscribe<num>(DataPath(pathStr));
    }
    return ValueNotifier(resolveDynamicNumber(definition));
  }

  /// Subscribes to a v0.9 DynamicBoolean.
  ValueNotifier<bool?> subscribeToBool(Object? definition) {
    if (definition is bool) {
      return ValueNotifier(definition);
    }
    if (definition is Map && definition.containsKey('path')) {
      final pathStr = definition['path'] as String;
      return subscribe<bool>(DataPath(pathStr));
    }
    return ValueNotifier(resolveDynamicBool(definition));
  }

  /// Subscribes to a v0.9 DynamicStringList.
  ValueNotifier<List<Object?>?> subscribeToObjectArray(Object? definition) {
    if (definition is List) {
      return ValueNotifier(definition);
    }
    if (definition is Map && definition.containsKey('path')) {
      final pathStr = definition['path'] as String;
      return subscribe<List<Object?>>(DataPath(pathStr));
    }
    // Fallback to resolving it once if possible (though
    // resolveDynamicStringList returns List<String>)
    if (definition is Map && definition.containsKey('call')) {
      final Object? result = _executeFunction(definition);
      if (result is List) return ValueNotifier(result);
    }
    return ValueNotifier(null);
  }

  /// Evaluates a v0.9 DynamicString, handling interpolation and function calls.
  ///
  /// [definition] can be:
  /// - String: literal with potential "${...}" interpolation.
  /// - Map {'path': '...'}: data binding.
  /// - Map {'call': '...'}: function call.
  String? resolveDynamicString(Object? definition) {
    return _resolveDynamicValue<String>(definition);
  }

  /// Evaluates a v0.9 DynamicNumber.
  num? resolveDynamicNumber(Object? definition) {
    return _resolveDynamicValue<num>(definition);
  }

  /// Evaluates a v0.9 DynamicBoolean.
  bool? resolveDynamicBool(Object? definition) {
    return _resolveDynamicValue<bool>(definition);
  }

  /// Evaluates a v0.9 DynamicStringList.
  List<String>? resolveDynamicStringList(Object? definition) {
    return _resolveDynamicValue<List<String>>(definition);
  }

  T? _resolveDynamicValue<T>(Object? definition) {
    if (definition == null) return null;

    if (definition is T) {
      if (definition is String) {
        // Handle interpolation for strings
        return _interpolate(definition) as T;
      }
      return definition as T;
    }

    if (definition is Map) {
      if (definition.containsKey('path')) {
        final pathStr = definition['path'] as String;
        return getValue<T>(DataPath(pathStr));
      }
      if (definition.containsKey('call')) {
        return _executeFunction(definition) as T?;
      }
    }
    return null;
  }

  Object? _executeFunction(Map<dynamic, dynamic> callDef) {
    final functionName = callDef['call'] as String;
    final List<Object?> args = (callDef['args'] as List?) ?? [];

    // Resolve args recursively
    final List<Object?> resolvedArgs = args.map(_resolveArg).toList();

    return FunctionRegistry.instance.execute(functionName, resolvedArgs);
  }

  Object? _resolveArg(Object? arg) {
    if (arg is Map) {
      if (arg.containsKey('path')) {
        return getValue(DataPath(arg['path'] as String));
      }
      if (arg.containsKey('call')) return _executeFunction(arg);
    }
    if (arg is String) return _interpolate(arg);
    return arg;
  }

  String _interpolate(String value) {
    // Simple interpolation handling: ${path} or ${function()}
    // This is a simplified regex-based interpolator for Phase 1.
    // It does NOT support nested braces cleanly yet, but covers basic cases.
    // TODO: Implement full recursive parser for nested expressions.

    return value.replaceAllMapped(RegExp(r'\${([^}]+)}'), (match) {
      final String expression = match.group(1)!;
      // Expression can be a path or a function call.
      // If it starts with '/', it is likely a path.
      // If it looks like 'func(...)', it is a function call.

      if (expression.contains('(') && expression.endsWith(')')) {
        // It's a function call in string format?
        // v0.9 spec: ${now()} or ${formatDate(${/date}, 'yyyy')}
        // Complexity: parsing arguments inside string expression is hard with
        // regex.
        // fallback: return raw match if complex, implementing full parser
        // later.
        return match.group(0)!;
      }

      // Assume path
      final Object? val = getValue<Object?>(DataPath(expression));
      return val?.toString() ?? '';
    });
  }
}

/// Manages the application's Object? data model and provides
/// a subscription-based mechanism for reactive UI updates.
class DataModel {
  JsonMap _data = {};
  final Map<DataPath, ValueNotifier<Object?>> _subscriptions = {};
  final Map<DataPath, ValueNotifier<Object?>> _valueSubscriptions = {};

  /// The full contents of the data model.
  JsonMap get data => _data;

  /// Updates the data model at a specific absolute path and notifies all
  /// relevant subscribers.
  void update(DataPath? absolutePath, Object? contents) {
    genUiLogger.info(
      'DataModel.update: path=$absolutePath, contents='
      '${const JsonEncoder.withIndent('  ').convert(contents)}',
    );
    if (absolutePath == null || absolutePath.segments.isEmpty) {
      if (contents is List) {
        _data = _parseDataModelContents(contents);
      } else if (contents is Map) {
        // Permissive: Allow a map to be sent for the root, even though the
        // schema expects a list.
        genUiLogger.info(
          'DataModel.update: contents for root path is a Map, not a '
          'List: $contents',
        );
        _data = Map<String, Object?>.from(contents);
      } else {
        genUiLogger.warning(
          'DataModel.update: contents for root path is not a List or '
          'Map: $contents',
        );
        _data = <String, Object?>{}; // Fallback
      }
      _notifySubscribers(DataPath.root);
      return;
    }

    _updateValue(_data, absolutePath.segments, contents);
    _notifySubscribers(absolutePath);
  }

  /// Subscribes to a specific absolute path in the data model.
  ValueNotifier<T?> subscribe<T>(DataPath absolutePath) {
    genUiLogger.info('DataModel.subscribe: path=$absolutePath');
    final T? initialValue = getValue<T>(absolutePath);
    if (_subscriptions.containsKey(absolutePath)) {
      final notifier = _subscriptions[absolutePath]! as ValueNotifier<T?>;
      notifier.value = initialValue;
      return notifier;
    }
    final notifier = ValueNotifier<T?>(initialValue);
    _subscriptions[absolutePath] = notifier;
    return notifier;
  }

  /// Subscribes to a specific absolute path in the data model, only notifying
  /// when the value at that exact path changes.
  ValueNotifier<T?> subscribeToValue<T>(DataPath absolutePath) {
    genUiLogger.info('DataModel.subscribeToValue: path=$absolutePath');
    final T? initialValue = getValue<T>(absolutePath);
    if (_valueSubscriptions.containsKey(absolutePath)) {
      final notifier = _valueSubscriptions[absolutePath]! as ValueNotifier<T?>;
      notifier.value = initialValue;
      return notifier;
    }
    final notifier = ValueNotifier<T?>(initialValue);
    _valueSubscriptions[absolutePath] = notifier;
    return notifier;
  }

  /// Retrieves a static, one-time value from the data model at the
  /// specified absolute path without creating a subscription.
  T? getValue<T>(DataPath absolutePath) {
    return _getValue(_data, absolutePath.segments) as T?;
  }

  /// Parses a list of content objects into a [JsonMap].
  ///
  /// Each item in [contents] is expected to be a `Map<String, Object?>`
  /// with a 'key' and a single 'valueString', 'valueNumber', 'valueBoolean',
  /// or 'valueMap' entry.
  JsonMap _parseDataModelContents(List<Object?> contents) {
    final newData = <String, Object?>{};
    for (final item in contents) {
      if (item is! Map<String, Object?> || !item.containsKey('key')) {
        genUiLogger.warning('Invalid item in dataModelUpdate contents: $item');
        continue;
      }

      final key = item['key'] as String;
      Object? value;
      var valueCount = 0;

      const valueKeys = [
        'valueString',
        'valueNumber',
        'valueBoolean',
        'valueMap',
      ];
      for (final valueKey in valueKeys) {
        if (item.containsKey(valueKey)) {
          if (valueCount == 0) {
            if (valueKey == 'valueMap') {
              if (item[valueKey] is List) {
                value = _parseDataModelContents(
                  (item[valueKey] as List).cast<Object?>(),
                );
              } else {
                genUiLogger.warning(
                  'valueMap for key "$key" is not a List: ${item[valueKey]}',
                );
              }
            } else {
              value = item[valueKey];
            }
          }
          valueCount++;
        }
      }

      if (valueCount == 0) {
        genUiLogger.warning(
          'No value field found for key "$key" in contents: $item',
        );
      } else if (valueCount > 1) {
        genUiLogger.warning(
          'Multiple value fields found for key "$key" in contents: $item. '
          'Using the first one found.',
        );
      }
      newData[key] = value;
    }
    return newData;
  }

  /// Retrieves a static, one-time value from the data model at the
  /// specified path segments without creating a subscription.
  ///
  /// The [current] parameter is the current node in the data model being
  /// traversed.
  /// The [segments] parameter is the list of remaining path segments to
  /// traverse.
  Object? _getValue(Object? current, List<String> segments) {
    if (segments.isEmpty) {
      return current;
    }

    final String segment = segments.first;
    final List<String> remaining = segments.sublist(1);

    if (current is Map) {
      return _getValue(current[segment], remaining);
    } else if (current is List) {
      final int? index = int.tryParse(segment);
      if (index != null && index >= 0 && index < current.length) {
        return _getValue(current[index], remaining);
      }
    }
    return null;
  }

  /// Updates the given path with a new value without creating a subscription.
  ///
  /// The [current] parameter is the current node in the data model being
  /// traversed.
  /// The [segments] parameter is the list of remaining path segments to
  /// traverse.
  /// The [value] parameter is the new value to set at the specified path.
  void _updateValue(Object? current, List<String> segments, Object? value) {
    if (segments.isEmpty) {
      return;
    }

    final String segment = segments.first;
    final List<String> remaining = segments.sublist(1);

    if (current is Map) {
      if (remaining.isEmpty) {
        current[segment] = value;
        return;
      }

      // If we are here, remaining is not empty.
      Object? nextNode = current[segment];
      if (nextNode == null) {
        // Create the node if it doesn't exist, so the recursive call can
        // populate it.
        final String nextSegment = remaining.first;
        final bool isNextSegmentListIndex = nextSegment.startsWith(
          RegExp(r'^\d+$'),
        );
        nextNode = isNextSegmentListIndex ? <dynamic>[] : <String, dynamic>{};
        current[segment] = nextNode;
      }
      _updateValue(nextNode, remaining, value);
    } else if (current is List) {
      final int? index = int.tryParse(segment);
      if (index != null && index >= 0) {
        if (remaining.isEmpty) {
          if (index < current.length) {
            current[index] = value;
          } else if (index == current.length) {
            current.add(value);
          } else {
            throw ArgumentError(
              'Index out of bounds for list update: index ($index) is greater '
              'than list length (${current.length}).',
            );
          }
        } else {
          if (index < current.length) {
            _updateValue(current[index], remaining, value);
          } else if (index == current.length) {
            // If the index is the length, we're adding a new item which
            // should be a map or list based on the next segment.
            if (remaining.first.startsWith(RegExp(r'^\d+$'))) {
              current.add(<dynamic>[]);
            } else {
              current.add(<String, dynamic>{});
            }
            _updateValue(current[index], remaining, value);
          } else {
            throw ArgumentError(
              'Index out of bounds for nested update: index ($index) is '
              'greater than list length (${current.length}).',
            );
          }
        }
      } else {
        genUiLogger.warning('Invalid list index segment: $segment');
      }
    }
  }

  void _notifySubscribers(DataPath path) {
    genUiLogger.info(
      'DataModel._notifySubscribers: notifying '
      '${_subscriptions.length} subscribers for path=$path',
    );
    for (final DataPath p in _subscriptions.keys) {
      if (p.startsWith(path) || path.startsWith(p)) {
        genUiLogger.info('  - Notifying subscriber for path=$p');
        final ValueNotifier<Object?>? subscriber = _subscriptions[p];
        if (subscriber != null) {
          subscriber.value = getValue<Object?>(p);
        }
      }
    }
    if (_valueSubscriptions.containsKey(path)) {
      genUiLogger.info('  - Notifying value subscriber for path=$path');
      final ValueNotifier<Object?>? subscriber = _valueSubscriptions[path];
      if (subscriber != null) {
        subscriber.value = getValue<Object?>(path);
      }
    }
  }
}
