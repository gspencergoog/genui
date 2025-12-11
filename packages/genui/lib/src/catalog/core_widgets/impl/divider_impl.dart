// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../../model/catalog_item.dart';
import '../../../primitives/simple_items.dart';

extension type DividerData.fromMap(JsonMap _json) {
  factory DividerData({String? axis}) => DividerData.fromMap({'axis': axis});

  String? get axis => _json['axis'] as String?;
}

Widget dividerBuilder(CatalogItemContext itemContext) {
  final dividerData = DividerData.fromMap(itemContext.data as JsonMap);
  if (dividerData.axis == 'vertical') {
    return const VerticalDivider();
  }
  return const Divider();
}
