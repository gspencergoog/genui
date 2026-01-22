// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:intl/intl.dart';

import '../primitives/logging.dart';

/// A registry of client-side functions available to A2UI schemas.
class FunctionRegistry {
  FunctionRegistry._();

  static final FunctionRegistry _instance = FunctionRegistry._();

  /// Returns the singleton instance of the function registry.
  static FunctionRegistry get instance => _instance;

  final Map<String, Function> _functions = {
    'required': (Object? value) {
      if (value == null) return false;
      if (value is String && value.isEmpty) return false;
      if (value is Iterable && value.isEmpty) return false;
      if (value is Map && value.isEmpty) return false;
      return true;
    },
    'regex': (Object? value, String pattern) {
      if (value is! String) return false;
      return RegExp(pattern).hasMatch(value);
    },
    'email': (Object? value) {
      if (value is! String) return false;
      // Simple email regex for validation
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      return emailRegex.hasMatch(value);
    },
    'length': (Object? value, {int? min, int? max}) {
      if (value is! String) return false;
      if (min != null && value.length < min) return false;
      if (max != null && value.length > max) return false;
      return true;
    },
    'numeric': (Object? value, {num? min, num? max}) {
      if (value is! num && value is! String) return false;
      final num? numValue = value is num
          ? value
          : num.tryParse(value as String);
      if (numValue == null) return false;
      if (min != null && numValue < min) return false;
      if (max != null && numValue > max) return false;
      return true;
    },
    'now': () {
      return DateTime.now().toIso8601String();
    },
    'formatDate': (Object? value, String format) {
      if (value == null) return '';
      DateTime? date;
      if (value is DateTime) {
        date = value;
      } else if (value is String) {
        date = DateTime.tryParse(value);
      } else if (value is int) {
        date = DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (date == null) return '';
      return DateFormat(format).format(date);
    },
    'string_format': (String format, List<Object?> args) {
      // logic handled in DataModel usually, but defining here for completeness
      // Implementation depends on how we want to invoke it.
      // For A2UI string_format, the interpolation usually happens BEFORE
      // calling this if used in logic,
      // but here we might just need to support standard specific formatters or
      // return as is?
      // Actually v0.9 string_format is mostly about the ${} interpolation which
      // happens at parse time
      // or recursively.
      return format; // Placeholder
    },
  };

  /// Registers a custom function.
  void register(String name, Function function) {
    if (_functions.containsKey(name)) {
      genUiLogger.warning('Overwriting existing function: $name');
    }
    _functions[name] = function;
  }

  /// Executes a named function with the given positional arguments.
  Object? execute(String name, List<Object?> args) {
    final Function? func = _functions[name];
    if (func == null) {
      genUiLogger.warning('Function not found: $name');
      return null;
    }

    try {
      return Function.apply(func, args);
    } catch (e, stack) {
      genUiLogger.severe('Error executing function $name', e, stack);
      return null;
    }
  }
}
