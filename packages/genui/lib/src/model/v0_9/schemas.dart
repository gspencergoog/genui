// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../primitives/simple_items.dart';
import '../catalog.dart';
import '../catalog_item.dart';

/// Provides a set of pre-defined, reusable schema objects for common
/// A2UI patterns, simplifying the creation of CatalogItem definitions.
class A2uiSchemas {
  /// The JSON content of server_to_client.json.
  static const String serverToClientJson = r'''
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://a2ui.dev/specification/0.9/server_to_client.json",
  "title": "A2UI Message Schema",
  "description": "Describes a JSON payload for an A2UI (Agent to UI) message, which is used to dynamically construct and update user interfaces.",
  "type": "object",
  "oneOf": [
    { "$ref": "#/$defs/CreateSurfaceMessage" },
    { "$ref": "#/$defs/UpdateComponentsMessage" },
    { "$ref": "#/$defs/UpdateDataModelMessage" },
    { "$ref": "#/$defs/DeleteSurfaceMessage" }
  ],
  "$defs": {
    "CreateSurfaceMessage": {
      "properties": {
        "createSurface": {
          "type": "object",
          "description": "Signals the client to create a new surface and begin rendering it. When this message is sent, the client will expect 'updateComponents' and/or 'updateDataModel' messages for the same surfaceId that define the component tree.",
          "properties": {
            "surfaceId": {
              "type": "string",
              "description": "The unique identifier for the UI surface to be rendered."
            },
            "catalogId": {
              "title": "Catalog ID",
              "description": "A string that uniquely identifies this catalog. It is recommended to prefix this with an internet domain that you own, to avoid conflicts e.g. mycompany.com:somecatalog'.",
              "type": "string"
            }
          },
          "required": ["surfaceId", "catalogId"],
          "additionalProperties": false
        }
      },
      "required": ["createSurface"],
      "additionalProperties": false
    },
    "UpdateComponentsMessage": {
      "properties": {
        "updateComponents": {
          "type": "object",
          "description": "Updates a surface with a new set of components. This message can be sent multiple times to update the component tree of an existing surface. One of the components in one of the components lists MUST have an 'id' of 'root' to serve as the root of the component tree. The createSurface message MUST have been previously sent with the 'catalogId' that is in this message.",
          "properties": {
            "surfaceId": {
              "type": "string",
              "description": "The unique identifier for the UI surface to be updated."
            },
            "components": {
              "type": "array",
              "description": "A list containing all UI components for the surface.",
              "minItems": 1,
              "items": {
                "$ref": "standard_catalog_definition.json#/$defs/anyComponent"
              }
            }
          },
          "required": ["surfaceId", "components"],
          "additionalProperties": false
        }
      },
      "required": ["updateComponents"],
      "additionalProperties": false
    },
    "UpdateDataModelMessage": {
      "properties": {
        "updateDataModel": {
          "type": "object",
          "description": "Updates the data model for an existing surface. This message can be sent multiple times to update the data model. The createSurface message MUST have been previously sent with the 'catalogId' that is in this message.",
          "properties": {
            "surfaceId": {
              "type": "string",
              "description": "The unique identifier for the UI surface this data model update applies to."
            },
            "path": {
              "type": "string",
              "description": "An optional path to a location within the data model (e.g., '/user/name'). If omitted, or set to '/', refers to the entire data model."
            },
            "op": {
              "type": "string",
              "description": "The operation to perform on the data model. Defaults to 'replace' if omitted.",
              "enum": ["add", "replace", "remove"]
            },
            "value": {
              "description": "The data to be updated in the data model. Required for 'add' and 'replace' operations. Not allowed for 'remove' operation.",
              "additionalProperties": true
            }
          },
          "required": ["surfaceId"],
          "additionalProperties": false
        }
      },
      "required": ["updateDataModel"],
      "additionalProperties": false
    },
    "DeleteSurfaceMessage": {
      "properties": {
        "deleteSurface": {
          "type": "object",
          "description": "Signals the client to delete the surface identified by 'surfaceId'. The createSurface message MUST have been previously sent with the 'catalogId' that is in this message.",
          "properties": {
            "surfaceId": {
              "type": "string",
              "description": "The unique identifier for the UI surface to be deleted."
            }
          },
          "required": ["surfaceId"],
          "additionalProperties": false
        }
      },
      "required": ["deleteSurface"],
      "additionalProperties": false
    }
  }
}
''';

  /// The JSON content of common_types.json.
  static const String commonTypesJson = r'''
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://a2ui.dev/specification/0.9/common_types.json",
  "title": "A2UI Common Types",
  "description": "Common type definitions used across A2UI schemas.",
  "$defs": {
    "stringOrPath": {
      "description": "Represents a value that can be either a literal string or a path to a value in the data model.",
      "oneOf": [
        { "type": "string" },
        {
          "type": "object",
          "properties": {
            "path": { "type": "string" }
          },
          "required": ["path"],
          "additionalProperties": false
        }
      ]
    },
    "numberOrPath": {
      "description": "Represents a value that can be either a literal number or a path to a value in the data model.",
      "oneOf": [
        { "type": "number" },
        {
          "type": "object",
          "properties": {
            "path": { "type": "string" }
          },
          "required": ["path"],
          "additionalProperties": false
        }
      ]
    },
    "booleanOrPath": {
      "description": "Represents a value that can be either a literal boolean or a path to a value in the data model.",
      "oneOf": [
        { "type": "boolean" },
        {
          "type": "object",
          "properties": {
            "path": { "type": "string" }
          },
          "required": ["path"],
          "additionalProperties": false
        }
      ]
    },
    "stringArrayOrPath": {
      "description": "Represents a value that can be either a literal array of strings or a path to a value in the data model.",
      "oneOf": [
        {
          "type": "array",
          "items": { "type": "string" }
        },
        {
          "type": "object",
          "properties": {
            "path": { "type": "string" }
          },
          "required": ["path"],
          "additionalProperties": false
        }
      ]
    },
    "id": {
      "type": "string",
      "description": "The unique identifier for this component."
    },
    "ComponentCommon": {
      "type": "object",
      "properties": {
        "id": { "$ref": "#/$defs/id" },
        "weight": {
          "type": "number",
          "description": "The relative weight of this component within a Row or Column. This is similar to the CSS 'flex-grow' property."
        }
      },
      "required": ["id"]
    },
    "contextValue": {
      "description": "A value that can be a string, number, boolean, or a path to a value.",
      "oneOf": [
        { "type": "string" },
        { "type": "number" },
        { "type": "boolean" },
        {
          "type": "object",
          "properties": { "path": { "type": "string" } },
          "required": ["path"],
          "additionalProperties": false
        }
      ]
    },
    "childrenProperty": {
      "oneOf": [
        {
          "type": "array",
          "items": { "type": "string" },
          "description": "A static list of child component IDs."
        },
        {
          "type": "object",
          "description": "A template for generating a dynamic list of children from a data model list. The `componentId` is the component to use as a template.",
          "properties": {
            "componentId": {
              "$ref": "#/$defs/id"
            },
            "path": {
              "type": "string",
              "description": "The path to the list of component property objects in the data model."
            }
          },
          "required": ["componentId", "path"],
          "additionalProperties": false
        }
      ]
    }
  }
}
''';

  /// Schema for a value that can be either a literal string or a
  /// data-bound path to a string in the DataModel.
  ///
  /// If `enumValues` are provided, the string value (either literal or at the
  /// path) must be one of the values in the enum.
  static Schema stringReference({
    String? description,
    List<String>? enumValues,
  }) {
    if (enumValues != null && enumValues.isNotEmpty) {
      final literalSchema = S.string(enumValues: enumValues);
      final pathSchema = S.object(
        properties: {'path': S.string()},
        required: ['path'],
        additionalProperties: false,
      );

      return S.combined(
        oneOf: [literalSchema, pathSchema],
        description: description,
      );
    }
    return S.combined(
      $ref: 'common_types.json#/\$defs/stringOrPath',
      description: description,
    );
  }

  /// Schema for a value that can be either a literal number or a
  /// data-bound path to a number in the DataModel.
  /// Schema for a value that can be either a literal number or a
  /// data-bound path to a number in the DataModel.
  static Schema numberReference({String? description}) => S.combined(
    $ref: 'common_types.json#/\$defs/numberOrPath',
    description: description,
  );

  /// Schema for a value that can be either a literal boolean or a
  /// data-bound path to a boolean in the DataModel.
  /// Schema for a value that can be either a literal boolean or a
  /// data-bound path to a boolean in the DataModel.
  static Schema booleanReference({String? description}) => S.combined(
    $ref: 'common_types.json#/\$defs/booleanOrPath',
    description: description,
  );

  /// Schema for a property that holds a reference to a single child
  /// component by its ID.
  static Schema componentReference({String? description}) =>
      S.string(description: description);

  /// Schema for a property that holds a list of child components,
  /// either as an explicit list of IDs or a data-bound template.
  /// Schema for a property that holds a list of child components,
  /// either as an explicit list of IDs or a data-bound template.
  static Schema childrenProperty({String? description}) => S.combined(
    $ref: 'common_types.json#/\$defs/childrenProperty',
    description: description,
  );

  /// Schema for a user-initiated action, including the action name
  /// and a context map of key-value pairs.
  /// Schema for a user-initiated action, including the action name
  /// and a context map of key-value pairs.
  static Schema action({String? description}) => S.object(
    description: description,
    properties: {
      'name': S.string(),
      'context': S.object(
        description:
            '''A JSON object containing the key-value pairs for the action context. Values can be literals or paths. Use literal values unless the value must be dynamically bound to the data model. Do NOT use paths for static IDs.''',
        additionalProperties: S.combined(
          $ref: 'common_types.json#/\$defs/contextValue',
        ),
      ),
    },
    required: ['name'],
    additionalProperties: false,
  );

  /// Schema for a value that can be either a literal array of strings or a
  /// data-bound path to an array of strings in the DataModel.
  /// Schema for a value that can be either a literal array of strings or a
  /// data-bound path to an array of strings in the DataModel.
  static Schema stringArrayReference({String? description}) => S.combined(
    $ref: 'common_types.json#/\$defs/stringArrayOrPath',
    description: description,
  );

  /// Schema for a value that can be either a literal array of objects (maps)
  /// or a data-bound path to an array of objects in the DataModel.
  static Schema objectArrayReference({String? description}) => S.combined(
    oneOf: [
      S.list(items: S.object(additionalProperties: true)),
      S.object(
        properties: {
          'path': S.string(
            description: 'A relative or absolute path in the data model.',
          ),
        },
        required: ['path'],
        additionalProperties: false,
      ),
    ],
    description: description,
  );

  /// Schema for a createSurface message, which initializes a surface.
  static Schema createSurfaceSchema() => S.object(
    properties: {
      surfaceIdKey: S.string(
        description: 'The surface ID of the surface to create.',
      ),
      'catalogId': S.string(
        description: 'The catalog ID to use for this surface.',
      ),
    },
    required: [surfaceIdKey, 'catalogId'],
  );

  /// Schema for a `deleteSurface` message which will delete the given surface.
  static Schema surfaceDeletionSchema() => S.object(
    properties: {surfaceIdKey: S.string()},
    required: [surfaceIdKey],
  );

  /// Schema for a `updateDataModel` message which will update the given path in
  /// the data model. If the path is omitted, the entire data model is replaced.
  static Schema updateDataModelSchema() => S.object(
    properties: {
      surfaceIdKey: S.string(),
      'path': S.string(),
      'op': S.string(
        description: 'The operation to perform (add, replace, remove).',
        enumValues: ['add', 'replace', 'remove'],
      ),
      'value': S.any(description: 'The new value to write to the data model.'),
    },
    required: [surfaceIdKey, 'value'],
  );

  /// Schema for a `updateComponents` message which defines the components to be
  /// rendered on a surface.
  static Schema updateComponentsSchema(Catalog catalog) => S.object(
    properties: {
      surfaceIdKey: S.string(
        description:
            'The unique identifier for the UI surface to create or '
            'update. If you are adding a new surface this *must* be a '
            'new, unique identified that has never been used for any '
            'existing surfaces shown.',
      ),
      'components': S.list(
        description: 'A list of component definitions.',
        minItems: 1,
        items: S.object(
          description:
              'Represents a *single* component in a UI widget tree. '
              'This component could be one of many supported types.',
          properties: {
            'id': S.string(
              description:
                  'The unique identifier for this component. The root '
                  "component of the surface MUST have the id 'root'.",
            ),
            'weight': S.integer(
              description:
                  'Optional layout weight for use in Row/Column children.',
            ),
            'component': S.string(
              description: 'The type of the component.',
              enumValues:
                  ((catalog.definition as ObjectSchema)
                              .properties!['components']!
                          as ObjectSchema)
                      .properties!
                      .keys
                      .toList(),
            ),
          },
          required: ['id', 'component'],
          additionalProperties: true,
        ),
      ),
    },
    required: [surfaceIdKey, 'components'],
  );

  /// Builds a catalog schema that matches the standard catalog definition
  /// structure.
  static Map<String, dynamic> buildCatalogSchema(Catalog catalog) {
    final Map<String, dynamic> defs = {};
    final List<Map<String, dynamic>> oneOf = [];

    // Theme definition
    defs['Theme'] = {
      'type': 'object',
      'description': 'Theming information for the UI.',
      'properties': {
        'font': {
          'type': 'string',
          'description': 'The primary font for the UI.',
        },
        'primaryColor': {
          'type': 'string',
          'description':
              'The primary UI color as a hexadecimal code (e.g., \'#00BFFF\').',
          'pattern': '^#[0-9a-fA-F]{6}\$',
        },
      },
      'additionalProperties': false,
    };

    for (final CatalogItem item in catalog.items) {
      dynamic rawSchema = item.dataSchema.toJson();
      if (rawSchema is String) {
        rawSchema = jsonDecode(rawSchema);
      }
      final itemSchema = rawSchema as Map<String, dynamic>;
      final properties = Map<String, dynamic>.from(
        itemSchema['properties'] as Map? ?? {},
      );
      properties['component'] = {'const': item.name};

      final required = List<String>.from(itemSchema['required'] as List? ?? []);
      if (!required.contains('component')) {
        required.insert(0, 'component');
      }

      defs[item.name] = {
        'type': 'object',
        'allOf': [
          {'\$ref': 'common_types.json#/\$defs/ComponentCommon'},
          {
            'type': 'object',
            'properties': properties,
            'required': required,
            if (itemSchema.containsKey('description'))
              'description': itemSchema['description'],
          },
        ],
        'unevaluatedProperties': false,
      };
      oneOf.add({'\$ref': '#/\$defs/${item.name}'});
    }

    defs['anyComponent'] = {
      'oneOf': oneOf,
      'discriminator': {'propertyName': 'component'},
    };

    return {
      '\$schema': 'https://json-schema.org/draft/2020-12/schema',
      '\$id':
          catalog.catalogId ??
          'https://a2ui.dev/specification/0.9/standard_catalog_definition.json',
      'title': 'A2UI Component Catalog',
      'description': 'Definitions for the standard catalog of A2UI components.',
      '\$defs': defs,
    };
  }
}
