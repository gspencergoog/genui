// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../model/a2ui_message.dart';
import '../model/a2ui_protocol.dart';
import '../model/catalog.dart';
import '../model/chat_message.dart';
import '../model/data_model.dart';
import '../model/ui_models.dart';
import '../primitives/logging.dart';
import 'genui_host.dart';

/// Manages the state of all dynamic UI surfaces.
///
/// This class is the core state manager for the dynamic UI. It maintains a map
/// of all active UI "surfaces", where each surface is represented by a
/// `UiDefinition`. It provides the tools (`updateComponents`, `deleteSurface`,
/// `createSurface`) that the AI uses to manipulate the UI. It exposes a stream
/// of `GenUiUpdate` events so that the application can react to changes.
class A2uiMessageProcessor implements GenUiHost {
  /// Creates a new [A2uiMessageProcessor] with a list of supported widget
  /// catalogs.
  A2uiMessageProcessor({required this.catalogs});

  @override
  final Iterable<Catalog> catalogs;

  final _surfaces = <String, ValueNotifier<UiDefinition?>>{};
  final _surfaceUpdates = StreamController<GenUiUpdate>.broadcast();
  final _onSubmit = StreamController<UserUiInteractionMessage>.broadcast();

  final _dataModels = <String, DataModel>{};

  @override
  Map<String, DataModel> get dataModels => Map.unmodifiable(_dataModels);

  @override
  DataModel dataModelForSurface(String surfaceId) {
    return _dataModels.putIfAbsent(surfaceId, DataModel.new);
  }

  /// A map of all the surfaces managed by this manager, keyed by surface ID.
  Map<String, ValueNotifier<UiDefinition?>> get surfaces => _surfaces;

  @override
  Stream<GenUiUpdate> get surfaceUpdates => _surfaceUpdates.stream;

  /// A stream of user input messages generated from UI interactions.
  Stream<UserUiInteractionMessage> get onSubmit => _onSubmit.stream;

  @override
  void handleUiEvent(UiEvent event) {
    if (event is! UserActionEvent) {
      // Or handle other event types if necessary
      return;
    }

    final String eventJsonString = jsonEncode({'userAction': event.toMap()});
    _onSubmit.add(UserUiInteractionMessage.text(eventJsonString));
  }

  @override
  void emitUpdate(GenUiUpdate update) {
    if (!_surfaceUpdates.isClosed) {
      _surfaceUpdates.add(update);
    }
  }

  @override
  void removeSurface(String surfaceId) {
    if (_surfaces.containsKey(surfaceId)) {
      genUiLogger.info('Deleting surface $surfaceId');
      final ValueNotifier<UiDefinition?>? notifier = _surfaces.remove(
        surfaceId,
      );
      notifier?.dispose();
      _dataModels.remove(surfaceId);
      emitUpdate(SurfaceRemoved(surfaceId));
    }
  }

  @override
  ValueNotifier<UiDefinition?> getSurfaceNotifier(String surfaceId) {
    if (!_surfaces.containsKey(surfaceId)) {
      genUiLogger.fine('Adding new surface $surfaceId');
    } else {
      genUiLogger.fine('Fetching surface notifier for $surfaceId');
    }
    return _surfaces.putIfAbsent(
      surfaceId,
      () => ValueNotifier<UiDefinition?>(null),
    );
  }

  /// Disposes of the resources used by this manager.
  void dispose() {
    _surfaceUpdates.close();
    _onSubmit.close();
    for (final ValueNotifier<UiDefinition?> notifier in _surfaces.values) {
      notifier.dispose();
    }
  }

  /// Handles an [A2uiMessage] and updates the UI accordingly.
  void handleMessage(A2uiMessage message, {A2uiProtocol? protocol}) {
    // If protocol is provided, delegate to it?
    // Or just switch on message types which imply protocol?
    // The user wants separation, so we should use the protocol if available,
    // or determine the protocol from the message type.

    // For now, we delegate based on type, but ideally we move this logic TO the
    // protocol. However, we don't hold the protocol instance here usually.
    // We can create default instances if needed, or static helpers.

    if (message is A2uiMessageV08) {
      const A2uiProtocolV08().handleMessage(message, this);
    } else if (message is A2uiMessageV09) {
      const A2uiProtocolV09().handleMessage(message, this);
    } else {
      // Shared messages
      switch (message) {
        case DeleteSurface():
          removeSurface(message.surfaceId);
        case ErrorMessage(:final code, :final message):
          genUiLogger.severe('Received A2UI Error: $code: $message');
        default:
          genUiLogger.warning('Unknown message type: $message');
      }
    }
  }
}
