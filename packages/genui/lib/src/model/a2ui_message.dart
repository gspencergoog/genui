// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'a2ui_protocol.dart';

/// A sealed class representing a message in the A2UI stream.
abstract class A2uiMessage {
  /// Creates an [A2uiMessage] with the given [version].
  const A2uiMessage(this.version);

  /// The protocol version of this message.
  final A2uiProtocolVersion version;
}
