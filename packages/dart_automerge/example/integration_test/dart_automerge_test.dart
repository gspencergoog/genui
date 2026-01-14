import 'dart:typed_data';

import 'package:dart_automerge/dart_automerge.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await RustLib.init();
  });

  test('Doc creation and update', () async {
    final Doc doc = await Doc.newDoc();
    await doc.update((current) async {
      return {
        'key': 'value',
        'list': [1, 2, 3],
      };
    });

    final Map<String, Object?> value = (await doc.value as Map)
        .cast<String, Object?>();
    expect(
      value,
      equals({
        'key': 'value',
        'list': [1, 2, 3],
      }),
    );
  });

  test('Doc sync', () async {
    final Doc doc1 = await Doc.newDoc();
    final Doc doc2 = await Doc.newDoc();

    // Update doc1
    await doc1.update((current) async {
      return {'shared': 'data'};
    });

    // Create sync states
    final SyncState syncState1 = await SyncState.create();
    final SyncState syncState2 = await SyncState.create();

    // Exchange messages until synchronized
    // Simulating a simple loop
    for (var i = 0; i < 5; i++) {
      final Uint8List? msg1 = await doc1.generateSyncMessage(syncState1);
      final Uint8List? msg2 = await doc2.generateSyncMessage(syncState2);

      if (msg1 == null && msg2 == null) break;

      if (msg1 != null) {
        await doc2.receiveSyncMessage(syncState2, msg1);
      }
      if (msg2 != null) {
        await doc1.receiveSyncMessage(syncState1, msg2);
      }
    }

    final Map<String, Object?> val2 = (await doc2.value as Map)
        .cast<String, Object?>();
    expect(val2, equals({'shared': 'data'}));
  });
}
