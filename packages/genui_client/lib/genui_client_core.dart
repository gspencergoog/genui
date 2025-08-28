// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The lower-level core API for the genui_client package.
///
/// This library exports the lower-level building blocks for users who need
/// more control over the client's behavior or want to integrate it into their
/// own state management solutions.
library;

export 'src/genui_client.dart';
export 'src/genui_manager.dart';
export 'src/model/ui_event_manager.dart';
export 'src/model/ui_models.dart' show UiActionEvent, UiChangeEvent, UiEvent;
