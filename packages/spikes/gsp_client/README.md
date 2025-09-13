# GenUI Streaming Protocol Client (gsp_client)

A Flutter package that implements the client-side responsibilities of the GenUI Streaming Protocol (GSP). This package allows a Flutter application to render and manage a user interface dynamically from a stream of JSONL messages.

## Overview

The GenUI Streaming Protocol (GSP) is a framework for building UIs where the structure, data, and events are defined by a server and interpreted by a client in real-time. This package provides the core client-side components to make this possible.

The core philosophy is a strict decoupling of:

- **The Catalog:** A contract defining the client's capabilities (widgets, properties, etc.).
- **The Layout:** The structure and arrangement of widgets, which can be updated incrementally.
- **The State:** The dynamic data that populates the layout, updated via stream messages.

This package provides the tools to parse a GSP stream and render a complete, dynamic Flutter widget tree.

## Features

- **JSONL Stream to Widget Rendering:** Dynamically build and update a Flutter UI from a stream of JSONL messages.
- **Real-time UI Updates:** Process layout and state changes from the server as they arrive, without requiring a full rebuild.
- **Extensible Widget Registry:** Register your own custom Flutter widgets to be used in the dynamic UI.
- **Dynamic Catalog Generation:** The client generates a `WidgetCatalog` at runtime based on the registered widgets.
- **State Management & Data Binding:** A simple but powerful state management solution with support for data binding and transformations.
- **Robust Error Handling:** Gracefully handles errors like missing widgets or cyclical layouts and displays a clear error UI instead of crashing.

## Getting Started

To use this package, add `gsp_client` as a dependency in your `pubspec.yaml` file.

```yaml
dependencies:
  gsp_client:
    path: <path_to_this_package> # Or use the pub.dev version when published
```

## Usage

Here is a simple example of how to use `GenUiView` to render a UI from a stream.

```dart
import 'dart:convert';

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:gsp_client/gsp_client.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const SimpleApp());
}

class SimpleApp extends StatelessWidget {
  const SimpleApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Create a registry and register the widgets your UI will use.
    final registry = WidgetCatalogRegistry()
      ..register(
        CatalogItem(
          name: 'Scaffold',
          builder: (context, node, properties, children) =>
              Scaffold(body: children['body']?.first),
          definition: WidgetDefinition(
            properties: ObjectSchema(
              properties: {
                'body': Schema.fromMap({'type': 'string'}),
              },
            ),
          ),
        ),
      )
      ..register(
        CatalogItem(
          name: 'Center',
          builder: (context, node, properties, children) =>
              Center(child: children['child']?.first),
          definition: WidgetDefinition(
            properties: ObjectSchema(
              properties: {
                'child': Schema.fromMap({'type': 'string'}),
              },
            ),
          ),
        ),
      )
      ..register(
        CatalogItem(
          name: 'Text',
          builder: (context, node, properties, children) {
            return Text(properties['data'] as String? ?? 'Default Text');
          },
          definition: WidgetDefinition(
            properties: ObjectSchema(
              properties: {
                'data': Schema.fromMap({'type': 'string'}),
              },
              required: ['data'],
            ),
          ),
        ),
      );

    // 2. The catalog is built from the registry.
    final catalog = registry.buildCatalog();

    // 3. Define the UI stream. In a real app, this would come from a server.
    final uiStream = Stream.fromIterable([
      json.encode({
        'messageType': 'StreamHeader',
        'formatVersion': '0.1.0',
        'initialState': {'message': 'Hello from GSP!'}
      }),
      json.encode({
        'messageType': 'Layout',
        'nodes': [
          {
            'id': 'root_scaffold',
            'type': 'Scaffold',
            'properties': {'body': 'center_node'},
          },
          {
            'id': 'center_node',
            'type': 'Center',
            'properties': {'child': 'text_node'},
          },
          {
            'id': 'text_node',
            'type': 'Text',
            'properties': {
              'data': {'\$bind': 'message'}
            },
          }
        ]
      }),
      json.encode({'messageType': 'LayoutRoot', 'rootId': 'root_scaffold'}),
    ]);

    // 4. Create the interpreter to process the stream.
    final interpreter = GspInterpreter(stream: uiStream, catalog: catalog);

    // 5. Use the GenUiView widget to render the UI.
    return MaterialApp(
      home: GenUiView(
        registry: registry,
        interpreter: interpreter,
        onEvent: (payload) {
          debugPrint(
            'Event received: ${payload.toJson()}',
          );
        },
      ),
    );
  }
}
```