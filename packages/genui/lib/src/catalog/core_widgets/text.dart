// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_dynamic_calls

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../core/widget_utilities.dart';
import '../../model/catalog_item.dart';
import '../../model/v0_9/schemas.dart';
import '../../primitives/simple_items.dart';

final _schema = S.object(
  properties: {
    'text': Schemas.stringReference(description: 'The text to display.'),
    'usageHint': S.string(
      description:
          'A hint for how the text should be styled (e.g., h1, h2, p).',
      enumValues: ['h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'p', 'caption'],
    ),
  },
  required: ['text'],
);

extension type _TextData.fromMap(JsonMap _json) {
  factory _TextData({required JsonMap text, String? usageHint}) =>
      _TextData.fromMap({
        'text': text,
        if (usageHint != null) 'usageHint': usageHint,
      });

  JsonMap get text => _json['text'] as JsonMap;
  String? get usageHint => _json['usageHint'] as String?;
}

/// A catalog item representing a block of styled text.
///
/// This widget displays text, optionally styled as a heading or caption.
/// It supports Markdown formatting.
final text = CatalogItem(
  name: 'Text',
  dataSchema: _schema,
  widgetBuilder: (itemContext) {
    final textData = _TextData.fromMap(itemContext.data as JsonMap);
    final String textContent =
        resolveStringReference(itemContext.dataContext, textData.text) ?? '';
    final String? usageHint = textData.usageHint;

    final ThemeData theme = Theme.of(itemContext.buildContext);
    final TextTheme textTheme = theme.textTheme;

    TextStyle? style;
    EdgeInsets padding = EdgeInsets.zero;

    switch (usageHint) {
      case 'h1':
        style = textTheme.headlineLarge;
        padding = const EdgeInsets.symmetric(vertical: 20.0);
      case 'h2':
        style = textTheme.headlineMedium;
        padding = const EdgeInsets.symmetric(vertical: 16.0);
      case 'h3':
        style = textTheme.headlineSmall;
        padding = const EdgeInsets.symmetric(vertical: 12.0);
      case 'h4':
        style = textTheme.titleLarge;
        padding = const EdgeInsets.symmetric(vertical: 10.0);
      case 'h5':
        style = textTheme.titleMedium;
        padding = const EdgeInsets.symmetric(vertical: 8.0);
      case 'h6':
        style = textTheme.titleSmall;
        padding = const EdgeInsets.symmetric(vertical: 6.0);
      case 'caption':
        style = textTheme.bodySmall;
      case 'p':
      default:
        style = textTheme.bodyMedium;
    }

    return Padding(
      padding: padding,
      child: MarkdownBody(
        data: textContent,
        styleSheet: MarkdownStyleSheet(
          p: style,
          h1: textTheme.headlineLarge,
          h2: textTheme.headlineMedium,
          h3: textTheme.headlineSmall,
          h4: textTheme.titleLarge,
          h5: textTheme.titleMedium,
          h6: textTheme.titleSmall,
        ),
      ),
    );
  },
  exampleData: [
    () => '''
      [
        {
          "id": "text",
          "component": "Text",
          "text": {
            "literalString": "Hello World"
          }
        }
      ]
    ''',
    () => '''
      [
        {
          "id": "heading",
          "component": "Text",
          "text": {
            "literalString": "Welcome"
          },
          "usageHint": "h1"
        }
      ]
    ''',
  ],
);
