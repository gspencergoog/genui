// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../../core/data_binder.dart';
import '../../../model/catalog_item.dart';
import '../../../model/data_model.dart';
import '../../../primitives/simple_items.dart';

extension type CheckBoxData.fromMap(JsonMap _json) {
  factory CheckBoxData({required Object? label, required Object? value}) =>
      CheckBoxData.fromMap({'label': label, 'value': value});

  Object? get label => _json['label'];
  Object? get value => _json['value'];
}

Widget checkBoxBuilder(CatalogItemContext itemContext) {
  final DataBinder binder = itemContext.binder;
  final checkBoxData = CheckBoxData.fromMap(itemContext.data as JsonMap);
  final ValueNotifier<String?> labelNotifier = binder.subscribeToString(
    checkBoxData.label,
  );
  final ValueNotifier<bool?> valueNotifier = binder.subscribeToBool(
    checkBoxData.value,
  );
  return ValueListenableBuilder<String?>(
    valueListenable: labelNotifier,
    builder: (context, label, child) {
      return ValueListenableBuilder<bool?>(
        valueListenable: valueNotifier,
        builder: (context, value, child) {
          return CheckboxListTile(
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              label ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            value: value ?? false,
            onChanged: (newValue) {
              final Object? val = checkBoxData.value;
              final String? path = val is Map && val.containsKey('path')
                  ? val['path'] as String?
                  : null;
              if (path != null) {
                binder.dataContext.update(DataPath(path), newValue);
              }
            },
          );
        },
      );
    },
  );
}
