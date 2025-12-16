// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/src/catalog/v0_9/core_catalog.dart';
import 'package:genui/src/model/catalog.dart';
import 'package:genui/src/model/v0_9/schemas.dart';

void main() {
  test('Generated catalog schema matches standard_catalog_definition.json', () {
    final Catalog catalog = CoreCatalogItems.asCatalog();
    final Map<String, dynamic> generatedSchema = A2uiSchemas.buildCatalogSchema(
      catalog,
    );

    var standardCatalogFile = File(
      'packages/genui/docs/specs/v0_9/standard_catalog_definition.json',
    );
    if (!standardCatalogFile.existsSync()) {
      standardCatalogFile = File(
        'docs/specs/v0_9/standard_catalog_definition.json',
      );
    }

    if (!standardCatalogFile.existsSync()) {
      // Fallback for running from package root vs monorepo root
      fail(
        '''Could not find standard_catalog_definition.json at ${standardCatalogFile.path} (CWD: ${Directory.current.path})''',
      );
    }

    final standardSchema =
        jsonDecode(standardCatalogFile.readAsStringSync())
            as Map<String, dynamic>;

    // Normalize both schemas for comparison (e.g. remove formatting
    // differences).
    _sortOneOf(generatedSchema);
    _sortOneOf(standardSchema);
    expect(generatedSchema, equals(standardSchema));
  });
}

void _sortOneOf(Map<String, dynamic> schema) {
  final defs = schema[r'$defs'] as Map<String, dynamic>?;
  if (defs != null) {
    final anyComponent = defs['anyComponent'] as Map<String, dynamic>?;
    if (anyComponent != null) {
      final oneOf = anyComponent['oneOf'] as List<dynamic>?;
      if (oneOf != null) {
        oneOf.sort((a, b) {
          final refA = (a as Map)[r'$ref'] as String;
          final refB = (b as Map)[r'$ref'] as String;
          return refA.compareTo(refB);
        });
      }
    }
  }
}
