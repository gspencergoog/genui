// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../../model/catalog_item.dart';
import '../../../primitives/simple_items.dart';

extension type CardData.fromMap(JsonMap _json) {
  factory CardData({required String child}) =>
      CardData.fromMap({'child': child});

  String get child => _json['child'] as String;
}

Widget cardBuilder(CatalogItemContext itemContext) {
  final cardData = CardData.fromMap(itemContext.data as JsonMap);
  return Card(
    color: Theme.of(itemContext.buildContext).colorScheme.surface,
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: itemContext.buildChild(cardData.child),
    ),
  );
}
