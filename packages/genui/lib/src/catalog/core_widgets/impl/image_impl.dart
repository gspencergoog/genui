// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../../core/data_binder.dart';
import '../../../model/catalog_item.dart';
import '../../../primitives/logging.dart';
import '../../../primitives/simple_items.dart';

extension type ImageData.fromMap(JsonMap _json) {
  factory ImageData({required JsonMap url, String? fit, String? usageHint}) =>
      ImageData.fromMap({'url': url, 'fit': fit, 'usageHint': usageHint});

  JsonMap get url => _json['url'] as JsonMap;
  BoxFit? get fit => _json['fit'] != null
      ? BoxFit.values.firstWhere((e) => e.name == _json['fit'] as String)
      : null;
  String? get usageHint => _json['usageHint'] as String?;
}

Widget imageBuilder(CatalogItemContext itemContext) {
  final DataBinder binder = itemContext.binder;
  final imageData = ImageData.fromMap(itemContext.data as JsonMap);
  final ValueNotifier<String?> notifier = binder.subscribeToString(
    imageData.url,
  );

  return ValueListenableBuilder<String?>(
    valueListenable: notifier,
    builder: (context, currentLocation, child) {
      final location = currentLocation;
      if (location == null || location.isEmpty) {
        genUiLogger.warning(
          'Image widget created with no URL at path: '
          '${itemContext.dataContext.path}',
        );
        return const SizedBox.shrink();
      }
      final BoxFit? fit = imageData.fit;
      final String? usageHint = imageData.usageHint;

      late Widget child;

      if (location.startsWith('assets/')) {
        child = Image.asset(location, fit: fit);
      } else {
        child = Image.network(location, fit: fit);
      }

      if (usageHint == 'avatar') {
        child = CircleAvatar(child: child);
      }

      if (usageHint == 'header') {
        return SizedBox(width: double.infinity, child: child);
      }

      final double size = switch (usageHint) {
        'icon' || 'avatar' => 32.0,
        'smallFeature' => 50.0,
        'mediumFeature' => 150.0,
        'largeFeature' => 400.0,
        _ => 150.0,
      };

      return SizedBox(width: size, height: size, child: child);
    },
  );
}
