// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';

import 'catalog.dart';
import 'tools.dart';

/// Provides a set of pre-defined, reusable schema objects for common
/// A2UI patterns, simplifying the creation of CatalogItem definitions.
class A2uiSchemas {
  /// Schema for a function call.
  static Schema functionCall() => S.object(
    properties: {
      'call': S.string(description: 'The name of the function to call.'),
      'args': S.list(description: 'Arguments passed to the function.'),
      'returnType': S.string(
        description: 'The expected return type of the function call.',
        enumValues: ['string', 'number', 'boolean', 'array', 'object', 'any'],
      ),
    },
    required: ['call'],
  );

  /// Schema for a value that can be either a literal string, a
  /// data-bound path to a string, or a function call returning a string.
  static Schema dynamicString({String? description, List<String>? enumValues}) {
    // We can't easily express the exact "oneOf" structure of v0.9 in this
    // builder DSL purely as a single "type" call if we want to mix primitive
    // and object types strictly,
    // but we can approximate it or use S.combined(oneOf: ...).
    //
    // v0.9 DynamicString:
    // oneOf: [ string, { path: string }, { allOf: [ FunctionCall, { returnType:
    // 'string' } ] } ]

    return S.combined(
      description: description,
      oneOf: [
        S.string(enumValues: enumValues),
        S.object(
          properties: {
            'path': S.string(
              description: 'A relative or absolute path in the data model.',
            ),
          },
          required: ['path'],
          additionalProperties: false,
        ),
        // Function call variant
        functionCall(),
      ],
    );
  }

  /// Schema for a value that can be either a literal number, a
  /// data-bound path to a number, or a function call returning a number.
  static Schema dynamicNumber({String? description}) {
    return S.combined(
      description: description,
      oneOf: [
        S.number(),
        S.object(
          properties: {
            'path': S.string(
              description: 'A relative or absolute path in the data model.',
            ),
          },
          required: ['path'],
          additionalProperties: false,
        ),
        functionCall(),
      ],
    );
  }

  /// Schema for a value that can be either a literal boolean, a
  /// data-bound path to a boolean, or a function call returning a boolean.
  static Schema dynamicBoolean({String? description}) {
    return S.combined(
      description: description,
      oneOf: [
        S.boolean(),
        S.object(
          properties: {
            'path': S.string(
              description: 'A relative or absolute path in the data model.',
            ),
          },
          required: ['path'],
          additionalProperties: false,
        ),
        functionCall(),
        // Logic expressions would go here too if we fully modeled
        // LogicExpression
      ],
    );
  }

  /// Schema for a dynamic string list.
  static Schema dynamicStringList({String? description}) {
    return S.combined(
      description: description,
      oneOf: [
        S.list(items: S.string()),
        S.object(
          properties: {
            'path': S.string(
              description: 'A relative or absolute path in the data model.',
            ),
          },
          required: ['path'],
          additionalProperties: false,
        ),
        functionCall(),
      ],
    );
  }

  /// Schema for the `ChildList` type (static array or template).
  static Schema childList({String? description}) {
    return S.combined(
      description: description,
      oneOf: [
        S.list(
          description: 'A static list of child component IDs.',
          items: S.string(),
        ),
        S.object(
          description:
              'A template for generating a dynamic list of children from a '
              'data model list.',
          properties: {
            'componentId': S.string(),
            'path': S.string(
              description:
                  'The path to the list of component property objects '
                  'in the data model.',
            ),
          },
          required: ['componentId', 'path'],
          additionalProperties: false,
        ),
      ],
    );
  }

  /// Schema for CheckRule (validation).
  static Schema checkRule() {
    return S.object(
      properties: {
        'message': S.string(
          description: 'The error message to display if the check fails.',
        ),
        'call': S.string(description: 'Function to call'),
        'args': S.list(),
      },
      required: ['message'],
    );
  }

  /// Schema for `checks` property.
  static Schema checks() {
    return S.list(
      description: 'A list of checks to perform.',
      items: checkRule(),
    );
  }

  /// Schema for a user-initiated action.
  static Schema action({String? description}) => S.object(
    description: description,
    properties: {
      'name': S.string(),
      'context': S.object(
        description: 'A map of name-value pairs to be sent with the action.',
        additionalProperties: S.any(), // Values can be any dynamic value
      ),
    },
    required: ['name'],
  );

  /// Schema for a createSurface message.
  static Schema createSurfaceSchema() => S.object(
    properties: {
      surfaceIdKey: S.string(
        description: 'The surface ID of the surface to create.',
      ),
      'catalogId': S.string(
        description:
            'The identifier of the component catalog to use for this surface.',
      ),
      'theme': S.object(
        properties: {
          'font': S.string(description: 'The base font for this surface'),
          'primaryColor': S.string(
            description: 'The seed color for the theme of this surface.',
          ),
        },
      ),
      'attachDataModel': S.boolean(
        description:
            'Whether to attach the current data model to every client message.',
      ),
    },
    required: [surfaceIdKey, 'catalogId'],
  );

  /// Schema for a `deleteSurface` message.
  static Schema deleteSurfaceSchema() => S.object(
    properties: {surfaceIdKey: S.string()},
    required: [surfaceIdKey],
  );

  /// Schema for a `updateDataModel` message.
  static Schema updateDataModelSchema() => S.object(
    properties: {
      surfaceIdKey: S.string(),
      'path': S.string(),
      'value': S.any(description: 'The new value to write to the data model.'),
    },
    required: [surfaceIdKey],
  );

  /// Schema for a `updateComponents` message.
  static Schema updateComponentsSchema(Catalog catalog) {
    return S.object(
      properties: {
        surfaceIdKey: S.string(
          description:
              'The unique identifier for the UI surface to create or update.',
        ),
        'components': S.list(
          description: 'A list of component definitions.',
          minItems: 1,
          items: S.object(
            description: 'Represents a *single* component in a UI widget tree.',
            properties: {
              'id': S.string(),
              'component': S.object(
                description: 'The component definition.',
                properties: {
                  for (final item in catalog.items)
                    item.name: item.dataSchema ?? S.object(),
                },
                minProperties: 1,
                maxProperties: 1,
                additionalProperties: false,
              ),
            },
            required: ['id', 'component'],
            additionalProperties: true,
          ),
        ),
      },
      required: [surfaceIdKey, 'components'],
    );
  }
}
