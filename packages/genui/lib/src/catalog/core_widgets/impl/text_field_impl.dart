// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../../core/data_binder.dart';
import '../../../model/catalog_item.dart';
import '../../../model/data_model.dart';
import '../../../model/ui_models.dart';
import '../../../primitives/simple_items.dart';

extension type TextFieldData.fromMap(JsonMap _json) {
  factory TextFieldData({
    Object? text,
    Object? label,
    String? usageHint,
    String? validationRegexp,
    JsonMap? onSubmittedAction,
  }) => TextFieldData.fromMap({
    'text': text,
    'label': label,
    'usageHint': usageHint,
    'validationRegexp': validationRegexp,
    'onSubmittedAction': onSubmittedAction,
  });

  Object? get text => _json['text'];
  Object? get label => _json['label'];
  String? get usageHint => _json['usageHint'] as String?;
  String? get validationRegexp => _json['validationRegexp'] as String?;
  JsonMap? get onSubmittedAction => _json['onSubmittedAction'] as JsonMap?;
}

class _TextField extends StatefulWidget {
  const _TextField({
    required this.initialValue,
    this.label,
    this.usageHint,
    this.validationRegexp,
    required this.onChanged,
    required this.onSubmitted,
  });

  final String initialValue;
  final String? label;
  final String? usageHint;
  final String? validationRegexp;
  final void Function(String) onChanged;
  final void Function(String) onSubmitted;

  @override
  State<_TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<_TextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_TextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(labelText: widget.label),
      obscureText: widget.usageHint == 'obscured',
      keyboardType: switch (widget.usageHint) {
        'number' => TextInputType.number,
        'longText' => TextInputType.multiline,
        'date' => TextInputType.datetime,
        _ => TextInputType.text,
      },
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
    );
  }
}

Widget textFieldBuilder(CatalogItemContext itemContext) {
  final DataBinder binder = itemContext.binder;
  final textFieldData = TextFieldData.fromMap(itemContext.data as JsonMap);
  final Object? valueRef = textFieldData.text;
  final String? path = valueRef is Map<String, Object?>
      ? valueRef['path'] as String?
      : null;
  final ValueNotifier<String?> notifier = binder.subscribeToString(valueRef);
  final ValueNotifier<String?> labelNotifier = binder.subscribeToString(
    textFieldData.label,
  );

  return ValueListenableBuilder<String?>(
    valueListenable: notifier,
    builder: (context, currentValue, child) {
      return ValueListenableBuilder(
        valueListenable: labelNotifier,
        builder: (context, label, child) {
          return _TextField(
            initialValue: currentValue ?? '',
            label: label,
            usageHint: textFieldData.usageHint,
            validationRegexp: textFieldData.validationRegexp,
            onChanged: (newValue) {
              if (path != null) {
                itemContext.dataContext.update(DataPath(path), newValue);
              }
            },
            onSubmitted: (newValue) {
              final JsonMap? actionData = textFieldData.onSubmittedAction;
              if (actionData == null) {
                return;
              }
              final actionName = actionData['name'] as String;
              final Object? contextDefinition = actionData['context'];
              final JsonMap resolvedContext = binder.resolveContext(
                contextDefinition,
              );
              itemContext.dispatchEvent(
                UserActionEvent(
                  name: actionName,
                  sourceComponentId: itemContext.id,
                  context: resolvedContext,
                ),
              );
            },
          );
        },
      );
    },
  );
}
