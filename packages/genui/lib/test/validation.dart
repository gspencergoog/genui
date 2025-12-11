// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import '../src/model/catalog.dart';
import '../src/model/catalog_item.dart';
import '../src/model/catalog_item.dart'
    show CatalogItem, ExampleBuilderCallback;

/// An error that occurred while validating a catalog item example.
class ExampleValidationError {
  /// Creates an [ExampleValidationError].
  ExampleValidationError(this.message);

  /// The error message.
  final String message;

  @override
  String toString() => message;
}

/// Validates the examples for a [CatalogItem].
Future<List<ExampleValidationError>> validateCatalogItemExamples(
  CatalogItem item,
  Catalog catalog,
) async {
  final errors = <ExampleValidationError>[];
  var index = 0;
  for (final ExampleBuilderCallback example in item.exampleData) {
    try {
      final String jsonString = example();
      final dynamic json = jsonDecode(jsonString);

      if (json is! List) {
        errors.add(
          ExampleValidationError(
            'Example $index for ${item.name} is not a list.',
          ),
        );
        continue;
      }

      for (final Object? component in json) {
        if (component is! Map) {
          errors.add(
            ExampleValidationError(
              'Example $index for ${item.name} contains a non-map component.',
            ),
          );
          continue;
        }
        // TODO: Validate against schema if possible.
        // For now, just checking basic structure.
        if (!component.containsKey('id')) {
          errors.add(
            ExampleValidationError(
              'Example $index for ${item.name} component missing id.',
            ),
          );
        }
        if (!component.containsKey('component')) {
          errors.add(
            ExampleValidationError(
              'Example $index for ${item.name} component missing component '
              'type.',
            ),
          );
        }
      }
    } catch (e) {
      errors.add(
        ExampleValidationError(
          'Example $index for ${item.name} failed to parse: $e',
        ),
      );
    }
    index++;
  }
  return errors;
}
