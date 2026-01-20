// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genui/genui.dart';

void main() {
  final tool = BeginRenderingTool(handleMessage: (msg) {}, catalogId: 'test');
  print(tool.catalogId);
}
