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
import '../model/v0_8/a2ui_protocol.dart' as v0_8_proto;
import '../model/v0_8/messages.dart' as v0_8;
import '../model/v0_9/a2ui_protocol.dart' as v0_9_proto;
import '../model/v0_9/messages.dart' as v0_9;
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
    if (protocol != null) {
      protocol.handleMessage(message, this);
      return;
    }

    // Fallback: try to guess based on type
    if (message is v0_9.UpdateComponents ||
        message is v0_9.UpdateDataModel ||
        message is v0_9.CreateSurface ||
        message is v0_9.DeleteSurface ||
        message is v0_9.ErrorMessage) {
      const v0_9_proto.A2uiProtocolV09().handleMessage(message, this);
    } else if (message is v0_8.SurfaceUpdate ||
        message is v0_8.DataModelUpdate ||
        message is v0_8.BeginRendering ||
        message is v0_8.DeleteSurface ||
        message is v0_8.ErrorMessage) {
      const v0_8_proto.A2uiProtocolV08().handleMessage(message, this);
    } else {
      genUiLogger.warning('Unknown message type: $message');
    }
  }
}
