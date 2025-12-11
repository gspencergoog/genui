// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:catalog_gallery/sample_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui/src/model/v0_9/messages.dart' as v0_9;

void main() {
  test('SampleParser parses valid sample string', () async {
    const sampleContent = '''
name: Test Sample
description: A test description
---
{"updateComponents": {"surfaceId": "default", "components": [{"id": "text1", "component": "Text", "text": {"literalString": "Hello"}}]}}
{"createSurface": {"surfaceId": "default", "catalogId": "standard"}}
''';

    final Sample sample = SampleParser.parseString(sampleContent);

    expect(sample.name, 'Test Sample');
    expect(sample.description, 'A test description');

    final List<A2uiMessage> messages = await sample.messages.toList();
    expect(messages.length, 2);
    expect(messages.first, isA<v0_9.UpdateComponents>());
    expect(messages.last, isA<v0_9.CreateSurface>());

    final update = messages.first as v0_9.UpdateComponents;
    expect(update.surfaceId, 'default');
    expect(update.components.length, 1);
    expect(update.components.first.type, 'Text');

    final begin = messages.last as v0_9.CreateSurface;
    expect(begin.surfaceId, 'default');
  });

  test('SampleParser throws on missing separator', () {
    const sampleContent = '''
name: Invalid Sample
No separator here
''';

    expect(
      () => SampleParser.parseString(sampleContent),
      throwsFormatException,
    );
  });
}
