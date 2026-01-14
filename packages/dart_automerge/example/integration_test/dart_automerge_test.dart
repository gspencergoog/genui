import 'package:dart_automerge/dart_automerge.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await RustLib.init();
  });

  test('Doc creation and update', () async {
    final doc = await Doc.newDoc();
    await doc.update((current) async {
      return {
        'key': 'value',
        'list': [1, 2, 3],
      };
    });

    final value = await doc.value;
    expect(
      value,
      equals({
        'key': 'value',
        'list': [1, 2, 3],
      }),
    );
  });

  test('Doc sync', () async {
    final doc1 = await Doc.newDoc();
    final doc2 = await Doc.newDoc();

    // Update doc1
    await doc1.update((current) async {
      return {'shared': 'data'};
    });

    // Create sync states
    final syncState1 = await SyncState.create();
    final syncState2 = await SyncState.create();

    // Exchange messages until synchronized
    // Simulating a simple loop
    for (var i = 0; i < 5; i++) {
      final msg1 = await doc1.generateSyncMessage(syncState1);
      final msg2 = await doc2.generateSyncMessage(syncState2);

      if (msg1 == null && msg2 == null) break;

      if (msg1 != null) {
        await doc2.receiveSyncMessage(syncState2, msg1);
      }
      if (msg2 != null) {
        await doc1.receiveSyncMessage(syncState1, msg2);
      }
    }

    final val2 = await doc2.value;
    expect(val2, equals({'shared': 'data'}));
  });
}
