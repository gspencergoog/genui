// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../../model/catalog_item.dart';

Widget videoBuilder(CatalogItemContext itemContext) {
  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 200, maxHeight: 100),
    child: const Placeholder(child: Center(child: Text('Video'))),
  );
}
