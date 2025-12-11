// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../../model/catalog_item.dart';
import '../../../model/data_model.dart';
import '../../../primitives/simple_items.dart';
import 'widget_helpers.dart';

extension type CheckBoxData.fromMap(JsonMap _json) {
  factory CheckBoxData({required JsonMap label, required JsonMap value}) =>
      CheckBoxData.fromMap({'label': label, 'value': value});

  JsonMap get label => _json['label'] as JsonMap;
  JsonMap get value => _json['value'] as JsonMap;
}

Widget checkBoxBuilder(CatalogItemContext itemContext) {
  final checkBoxData = CheckBoxData.fromMap(itemContext.data as JsonMap);
  final ValueNotifier<String?> labelNotifier = itemContext.dataContext
      .subscribeToString(checkBoxData.label);
  final ValueNotifier<bool?> valueNotifier = itemContext.dataContext
      .subscribeToBool(checkBoxData.value);
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
              final path = checkBoxData.value['path'] as String?;
              if (path != null) {
                itemContext.dataContext.update(DataPath(path), newValue);
              }
            },
          );
        },
      );
    },
  );
}
