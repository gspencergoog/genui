// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'a2a_gulf_connector.dart';
import 'genkit_gulf_connector.dart';
import 'gulf_connector.dart';

/// An enum to specify the type of server to connect to.
enum ServerType { a2a, genkit }

/// A factory function to create a [GulfConnector] based on the [type].
GulfConnector createGulfConnector({
  required ServerType type,
  required Uri url,
}) {
  switch (type) {
    case ServerType.a2a:
      return A2AGulfConnector(url: url);
    case ServerType.genkit:
      return GenkitGulfConnector(url: url);
  }
}
