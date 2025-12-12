// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../../core/data_binder.dart';
import '../../../model/catalog_item.dart';
import '../../../model/data_model.dart';
import '../../../primitives/simple_items.dart';

extension type SliderData.fromMap(JsonMap _json) {
  factory SliderData({required JsonMap value, JsonMap? min, JsonMap? max}) =>
      SliderData.fromMap({'value': value, 'min': min, 'max': max});

  JsonMap get value => _json['value'] as JsonMap;
  JsonMap? get min => _json['min'] as JsonMap?;
  JsonMap? get max => _json['max'] as JsonMap?;
}

Widget sliderBuilder(CatalogItemContext itemContext) {
  final DataBinder binder = itemContext.binder;
  final sliderData = SliderData.fromMap(itemContext.data as JsonMap);
  final ValueNotifier<num?> valueNotifier = binder.subscribeToNum(
    sliderData.value,
  );
  final ValueNotifier<num?> minNotifier = binder.subscribeToNum(
    sliderData.min ?? 0.0,
  );
  final ValueNotifier<num?> maxNotifier = binder.subscribeToNum(
    sliderData.max ?? 1.0,
  );

  return ListenableBuilder(
    listenable: Listenable.merge([valueNotifier, minNotifier, maxNotifier]),
    builder: (context, child) {
      final double min = (minNotifier.value ?? 0.0).toDouble();
      final double max = (maxNotifier.value ?? 1.0).toDouble();
      // Ensure min < max to avoid errors
      final effectiveMin = min;
      final double effectiveMax = max > min ? max : min + 1.0;

      final double val = (valueNotifier.value ?? effectiveMin).toDouble();
      final double effectiveVal = val.clamp(effectiveMin, effectiveMax);

      return Padding(
        padding: const EdgeInsetsDirectional.only(end: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Slider(
                value: effectiveVal,
                min: effectiveMin,
                max: effectiveMax,
                divisions: (effectiveMax - effectiveMin) > 0
                    ? (effectiveMax - effectiveMin).toInt()
                    : 1,
                onChanged: (newValue) {
                  final path = sliderData.value['path'] as String?;
                  if (path != null) {
                    binder.dataContext.update(DataPath(path), newValue);
                  }
                },
              ),
            ),
            Text(effectiveVal.toStringAsFixed(0)),
          ],
        ),
      );
    },
  );
}
