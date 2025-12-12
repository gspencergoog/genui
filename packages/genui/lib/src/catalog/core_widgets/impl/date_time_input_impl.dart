// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../../core/data_binder.dart';
import '../../../model/catalog_item.dart';
import '../../../model/data_model.dart';
import '../../../primitives/simple_items.dart';

extension type DateTimeInputData.fromMap(JsonMap _json) {
  factory DateTimeInputData({
    required JsonMap value,
    bool? enableDate,
    bool? enableTime,
    String? outputFormat,
  }) => DateTimeInputData.fromMap({
    'value': value,
    'enableDate': enableDate,
    'enableTime': enableTime,
    'outputFormat': outputFormat,
  });

  JsonMap get value => _json['value'] as JsonMap;
  bool get enableDate => (_json['enableDate'] as bool?) ?? true;
  bool get enableTime => (_json['enableTime'] as bool?) ?? true;
  String? get outputFormat => _json['outputFormat'] as String?;
}

Widget dateTimeInputBuilder(CatalogItemContext itemContext) {
  final DataBinder binder = itemContext.binder;
  final dateTimeInputData = DateTimeInputData.fromMap(
    itemContext.data as JsonMap,
  );
  final ValueNotifier<String?> valueNotifier = binder.subscribeToString(
    dateTimeInputData.value,
  );

  return ValueListenableBuilder<String?>(
    valueListenable: valueNotifier,
    builder: (context, value, child) {
      return ListTile(
        title: Text(value ?? 'Select a date/time'),
        onTap: () async {
          final path = dateTimeInputData.value['path'] as String?;
          if (path == null) {
            return;
          }
          if (dateTimeInputData.enableDate) {
            final DateTime? date = await showDatePicker(
              context: itemContext.buildContext,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              binder.dataContext.update(DataPath(path), date.toIso8601String());
            }
          }
          if (dateTimeInputData.enableTime) {
            final TimeOfDay? time = await showTimePicker(
              context: itemContext.buildContext,
              initialTime: TimeOfDay.now(),
            );
            if (time != null) {
              binder.dataContext.update(
                DataPath(path),
                time.format(itemContext.buildContext),
              );
            }
          }
        },
      );
    },
  );
}
