// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gulf_client/gulf_client.dart';

class AgentState with ChangeNotifier {
  AgentState() {
    unawaited(_fetchCard());
  }

  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  GulfInterpreter? _interpreter;
  GulfConnector? _connector;
  AgentCard? _agentCard;
  ServerType _serverType = ServerType.a2a;
  final _a2aUrlController = TextEditingController(
    text: 'http://localhost:10002',
  );
  final _genkitUrlController = TextEditingController(
    text: 'http://localhost:3400/gulfFlow',
  );

  GlobalKey<ScaffoldMessengerState> get scaffoldMessengerKey =>
      _scaffoldMessengerKey;
  GulfInterpreter? get interpreter => _interpreter;
  GulfConnector? get connector => _connector;
  AgentCard? get agentCard => _agentCard;
  ServerType get serverType => _serverType;
  TextEditingController get a2aUrlController => _a2aUrlController;
  TextEditingController get genkitUrlController => _genkitUrlController;

  @override
  void dispose() {
    _a2aUrlController.dispose();
    _genkitUrlController.dispose();
    _connector?.dispose();
    _interpreter?.dispose();
    super.dispose();
  }

  void setServerType(ServerType type) {
    if (_serverType != type) {
      _serverType = type;
      unawaited(_fetchCard());
      notifyListeners();
    }
  }

  Future<void> fetchCard() async {
    final urlText = _serverType == ServerType.a2a
        ? _a2aUrlController.text
        : _genkitUrlController.text;
    final url = Uri.tryParse(urlText);
    if (url == null) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Invalid URL')),
      );
      return;
    }

    // Clean up previous connections
    _connector?.dispose();
    _interpreter?.dispose();

    final newConnector = createGulfConnector(type: _serverType, url: url);
    try {
      final card = await newConnector.getAgentCard();
      _connector = newConnector;
      _agentCard = card;
      _interpreter = GulfInterpreter(stream: newConnector.stream);
      notifyListeners();
    } catch (e) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error fetching agent card: $e')),
      );
    }
  }

  Future<void> _fetchCard() async {
    await fetchCard();
  }
}
