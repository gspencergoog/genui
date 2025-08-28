// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/widgets.dart';
library;

import 'package:flutter/material.dart' show ElevatedButton;

import 'model/catalog.dart';
import 'widgets/checkbox_group.dart';
import 'widgets/column.dart';
import 'widgets/elevated_button.dart';
import 'widgets/image.dart';
import 'widgets/radio_group.dart';
import 'widgets/text.dart';
import 'widgets/text_field.dart';

/// The catalog of core widgets provided by the GenUI client.
///
/// This catalog includes common widgets like [Column], [Text],
/// [ElevatedButton], etc.
final coreCatalog = Catalog([
  elevatedButton,
  column,
  text,
  checkboxGroup,
  radioGroup,
  textField,
  image,
]);
