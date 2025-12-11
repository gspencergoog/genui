// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../../model/catalog_item.dart';
import '../../../primitives/simple_items.dart';

extension type ModalData.fromMap(JsonMap _json) {
  factory ModalData({
    required String entryPointChild,
    required String contentChild,
  }) => ModalData.fromMap({
    'entryPointChild': entryPointChild,
    'contentChild': contentChild,
  });

  String get entryPointChild => _json['entryPointChild'] as String;
  String get contentChild => _json['contentChild'] as String;
}

Widget modalBuilder(CatalogItemContext itemContext) {
  final modalData = ModalData.fromMap(itemContext.data as JsonMap);
  return itemContext.buildChild(modalData.entryPointChild);
}
