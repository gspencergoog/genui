// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_dynamic_calls

import 'package:flutter/material.dart';

import '../../../core/widget_utilities.dart';
import '../../../model/catalog_item.dart';
import '../../../model/ui_models.dart';
import '../../../primitives/logging.dart';
import '../../../primitives/simple_items.dart';

extension type ButtonData.fromMap(JsonMap _json) {
  factory ButtonData({
    required String child,
    required JsonMap action,
    bool primary = false,
  }) => ButtonData.fromMap({
    'child': child,
    'action': action,
    'primary': primary,
  });

  String get child => _json['child'] as String;
  JsonMap get action => _json['action'] as JsonMap;
  bool get primary => (_json['primary'] as bool?) ?? false;
}

Widget buttonBuilder(CatalogItemContext itemContext) {
  final buttonData = ButtonData.fromMap(itemContext.data as JsonMap);
  final Widget child = itemContext.buildChild(buttonData.child);
  final JsonMap actionData = buttonData.action;
  final actionName = actionData['name'] as String;
  final Map<String, Object?> contextDefinition =
      (actionData['context'] as Map<String, Object?>?) ?? {};

  genUiLogger.info('Building Button with child: ${buttonData.child}');
  final ColorScheme colorScheme = Theme.of(
    itemContext.buildContext,
  ).colorScheme;
  final bool primary = buttonData.primary;

  final TextStyle? textStyle = Theme.of(itemContext.buildContext)
      .textTheme
      .bodyLarge
      ?.copyWith(
        color: primary ? colorScheme.onPrimary : colorScheme.onSurface,
      );

  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: primary ? colorScheme.primary : colorScheme.surface,
      foregroundColor: primary ? colorScheme.onPrimary : colorScheme.onSurface,
    ).copyWith(textStyle: WidgetStatePropertyAll(textStyle)),
    onPressed: () {
      final JsonMap resolvedContext = resolveContext(
        itemContext.dataContext,
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
    child: child,
  );
}
