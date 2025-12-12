// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../model/data_model.dart';
import '../../primitives/simple_items.dart';

/// Resolves a context map definition against a [DataContext].
JsonMap resolveContext(
  DataContext dataContext,
  Map<String, Object?> contextDefinitions,
) {
  final resolved = <String, Object?>{};
  for (final MapEntry<String, Object?> entry in contextDefinitions.entries) {
    final String key = entry.key;
    final Object? value = entry.value;
    if (value is Map && value.containsKey('path')) {
      resolved[key] = dataContext.getValue(DataPath(value['path'] as String));
    } else {
      // It's a literal value (or a map without a path, which we treat as
      // literal for now, though schema might restrict what context values can
      // be).
      resolved[key] = value;
    }
  }
  return resolved;
}
