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
