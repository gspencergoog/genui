// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../../core/data_binder.dart';
import '../../../model/catalog_item.dart';
import '../../../model/data_model.dart';
import '../../../primitives/simple_items.dart';

extension type ChoicePickerData.fromMap(JsonMap _json) {
  factory ChoicePickerData({
    required Object? value,
    required Object? options,
    String? usageHint,
  }) => ChoicePickerData.fromMap({
    'value': value,
    'options': options,
    'usageHint': usageHint,
  });

  Object? get value => _json['value'];
  Object? get options => _json['options'];
  String? get usageHint => _json['usageHint'] as String?;
}

Widget choicePickerBuilder(CatalogItemContext itemContext) {
  final DataBinder binder = itemContext.binder;
  final choicePickerData = ChoicePickerData.fromMap(
    itemContext.data as JsonMap,
  );
  final ValueNotifier<List<Object?>?> selectionsNotifier = binder
      .subscribeToObjectArray(choicePickerData.value);
  final ValueNotifier<List<Object?>?> optionsNotifier = binder
      .subscribeToObjectArray(choicePickerData.options);

  return ValueListenableBuilder<List<Object?>?>(
    valueListenable: selectionsNotifier,
    builder: (context, selections, child) {
      return ValueListenableBuilder<List<Object?>?>(
        valueListenable: optionsNotifier,
        builder: (context, options, child) {
          if (options == null) {
            return const SizedBox.shrink();
          }
          return Column(
            children: options.map((optionObj) {
              final option = optionObj as JsonMap;
              final Object? labelObj = option['label'];
              final ValueNotifier<String?> labelNotifier;
              if (labelObj is String) {
                labelNotifier = ValueNotifier<String?>(labelObj);
              } else if (labelObj is JsonMap) {
                labelNotifier = binder.subscribeToString(labelObj);
              } else {
                labelNotifier = ValueNotifier<String?>(null);
              }
              final value = option['value'] as String;
              return ValueListenableBuilder<String?>(
                valueListenable: labelNotifier,
                builder: (context, label, child) {
                  if (choicePickerData.usageHint == 'mutuallyExclusive') {
                    final Object? groupValue = selections?.isNotEmpty == true
                        ? selections!.first
                        : null;
                    return RadioListTile<String>(
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      title: Text(
                        label ?? '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      value: value,
                      // ignore: deprecated_member_use
                      groupValue: groupValue is String ? groupValue : null,
                      // ignore: deprecated_member_use
                      onChanged: (newValue) {
                        final Object? val = choicePickerData.value;
                        final String? path =
                            val is Map && val.containsKey('path')
                            ? val['path'] as String?
                            : null;
                        if (path == null || newValue == null) {
                          return;
                        }
                        binder.dataContext.update(DataPath(path), [newValue]);
                      },
                    );
                  } else {
                    return CheckboxListTile(
                      title: Text(label ?? ''),
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: selections?.contains(value) ?? false,
                      onChanged: (newValue) {
                        final Object? val = choicePickerData.value;
                        final String? path =
                            val is Map && val.containsKey('path')
                            ? val['path'] as String?
                            : null;
                        if (path == null) {
                          return;
                        }
                        final List<String> newSelections =
                            selections?.map((e) => e.toString()).toList() ??
                            <String>[];
                        if (newValue ?? false) {
                          if (!newSelections.contains(value)) {
                            newSelections.add(value);
                          }
                        } else {
                          newSelections.remove(value);
                        }
                        binder.dataContext.update(
                          DataPath(path),
                          newSelections,
                        );
                      },
                    );
                  }
                },
              );
            }).toList(),
          );
        },
      );
    },
  );
}
