import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_automerge/src/rust/api/doc.dart';
import 'package:dart_automerge/src/rust/api/sync.dart' as sync_api;
import 'package:dart_automerge/src/rust/api/sync.dart' show SyncStateHandle;

class Doc {
  final DocHandle _handle;

  Doc._(this._handle);

  /// Creates a new, empty document.
  static Future<Doc> newDoc() async {
    final handle = await DocHandle.newInstance();
    return Doc._(handle);
  }

  /// Loads a document from a binary byte array.
  static Future<Doc> load(Uint8List bytes) async {
    final handle = await DocHandle.load(bytes: bytes);
    return Doc._(handle);
  }

  /// Gets the current state of the document as a plain Dart object (Map/List).
  Future<dynamic> get value async {
    final jsonStr = await _handle.hydrateJson();
    return jsonDecode(jsonStr);
  }

  /// Updates the document by providing a callback that modifies the logical state.
  ///
  /// The [handler] receives the current state. The return value of [handler]
  /// is reconciled into the document.
  Future<void> update(
    FutureOr<dynamic> Function(dynamic current) handler,
  ) async {
    final current = await value;
    final newValue = await handler(current);
    await reconcile(newValue);
  }

  /// Directly reconciles a new value into the document root.
  Future<void> reconcile(dynamic newValue) async {
    final jsonStr = jsonEncode(newValue);
    await _handle.reconcileJson(jsonStr: jsonStr);
  }

  /// Serializes the document to a byte array.
  Future<Uint8List> save() async {
    return _handle.save();
  }

  /// Forks the document at the current head.
  Future<Doc> fork() async {
    final newHandle = await _handle.fork();
    return Doc._(newHandle);
  }

  /// Merges another document into this one.
  Future<void> merge(Doc other) async {
    await _handle.merge(other: other._handle);
  }

  /// Generates a sync message to send to a peer.
  Future<Uint8List?> generateSyncMessage(SyncState syncState) async {
    return sync_api.generateSyncMessage(
      doc: _handle,
      syncState: syncState._handle,
    );
  }

  /// Receives a sync message from a peer and applies it.
  Future<void> receiveSyncMessage(
    SyncState syncState,
    Uint8List message,
  ) async {
    await sync_api.receiveSyncMessage(
      doc: _handle,
      syncState: syncState._handle,
      message: message,
    );
  }

  /// Internal handle access for advanced usage if needed
  DocHandle get handle => _handle;
}

class SyncState {
  final SyncStateHandle _handle;

  SyncState._(this._handle);

  static Future<SyncState> create() async {
    final handle = await SyncStateHandle.create();
    return SyncState._(handle);
  }

  Future<void> decodeMessage(Uint8List message) async {
    await SyncStateHandle.decodeMessage(message: message);
  }

  // SyncStateHandle get _handle => _handle;
}
