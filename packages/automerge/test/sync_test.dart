import 'dart:typed_data';

import 'package:automerge/automerge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await RustLib.init();
  });

  group('Sync', () {
    test('SyncState can be created', () async {
      final SyncState syncState = await SyncState.create();
      expect(syncState, isNotNull);
    });

    test('generateSyncMessage returns initial message (handshake)', () async {
      final Doc doc = await Doc.newDoc();
      final SyncState syncState = await SyncState.create();

      final Uint8List? msg = await doc.generateSyncMessage(syncState);
      expect(msg, isNotNull);
      expect(msg, isNotEmpty);
    });

    test('two docs can sync empty state', () async {
      final Doc doc1 = await Doc.newDoc();
      final Doc doc2 = await Doc.newDoc();

      final SyncState syncState1 = await SyncState.create();
      final SyncState syncState2 = await SyncState.create();

      // Initial exchange (should catch up to empty state/heads)
      // Usually one side generates a sync message to start.
      // Automerge sync protocol usually starts with a message even if empty if
      // it hasn't synced before. But let's verify behavior.

      // We simulate a loop until quiescence
      await syncDocs(doc1, syncState1, doc2, syncState2);

      final Object? val1 = await doc1.value;
      final Object? val2 = await doc2.value;
      expect(val1, equals(val2));
    });

    test('sync propagates changes', () async {
      final Doc doc1 = await Doc.newDoc();
      final Doc doc2 = await Doc.newDoc();

      await doc1.update((_) => {'foo': 'bar'});

      final SyncState syncState1 = await SyncState.create();
      final SyncState syncState2 = await SyncState.create();

      await syncDocs(doc1, syncState1, doc2, syncState2);

      final Object? val2 = await doc2.value;
      expect(val2, equals({'foo': 'bar'}));
    });

    test('bidirectional sync converges', () async {
      final Doc doc1 = await Doc.newDoc();
      final Doc doc2 = await Doc.newDoc();

      await doc1.update((_) => {'user1': 'Alice'});
      await doc2.update((_) => {'user2': 'Bob'});

      final SyncState syncState1 = await SyncState.create();
      final SyncState syncState2 = await SyncState.create();

      await syncDocs(doc1, syncState1, doc2, syncState2);

      final val1 = await doc1.value as Map<String, Object?>;
      final val2 = await doc2.value as Map<String, Object?>;

      expect(val1, equals(val2));
      expect(val1['user1'], equals('Alice'));
      expect(val1['user2'], equals('Bob'));
    });
  });
}

Future<void> syncDocs(
  Doc doc1,
  SyncState syncState1,
  Doc doc2,
  SyncState syncState2,
) async {
  var synced = false;
  var guard = 0;
  while (!synced && guard < 10) {
    synced = true;
    guard++;

    final Uint8List? msg1 = await doc1.generateSyncMessage(syncState1);
    final Uint8List? msg2 = await doc2.generateSyncMessage(syncState2);

    if (msg1 != null) {
      synced = false;
      await doc2.receiveSyncMessage(syncState2, msg1);
    }
    if (msg2 != null) {
      synced = false;
      await doc1.receiveSyncMessage(syncState1, msg2);
    }
  }
}
