import 'dart:async';

import 'package:fcp_client/fcp_client.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const GenUiExampleApp());
}

class GenUiExampleApp extends StatelessWidget {
  const GenUiExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GenUI Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const GenUiHomePage(),
    );
  }
}

class GenUiHomePage extends StatefulWidget {
  const GenUiHomePage({super.key});

  @override
  State<GenUiHomePage> createState() => _GenUiHomePageState();
}

class _GenUiHomePageState extends State<GenUiHomePage> {
  late final GspInterpreter interpreter;
  final registry = WidgetCatalogRegistry();

  @override
  void initState() {
    super.initState();
    final streamController = StreamController<String>();
    interpreter = GspInterpreter(
      stream: streamController.stream,
      catalog: registry.buildCatalog(),
    );

    // Add a sample stream of JSONL messages.
    streamController.add(
      '{"messageType": "StreamHeader", "formatVersion": "1.0.0", "initialState": {"greeting": "Hello", "user": {"name": "World"}}}',
    );
    streamController.add(
      '{"messageType": "Layout", "nodes": [{"id": "root", "type": "Column", "properties": {"children": ["greeting_text"]}}]}',
    );
    streamController.add(
      '{"messageType": "Layout", "nodes": [{"id": "greeting_text", "type": "Text", "properties": {"data": "\${greeting}, \${user.name}!"}}]}',
    );
    streamController.add('{"messageType": "LayoutRoot", "rootId": "root"}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GenUI Example')),
      body: GenUiView(
        interpreter: interpreter,
        registry: registry,
        onEvent: (request) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Event: ${request.event?.eventName} from ${request.event?.sourceNodeId}',
              ),
            ),
          );
        },
      ),
    );
  }
}
