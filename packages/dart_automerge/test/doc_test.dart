import 'dart:typed_data';

import 'package:dart_automerge/dart_automerge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await RustLib.init();
  });

  group('Doc', () {
    test('newDoc creates an empty document', () async {
      final Doc doc = await Doc.newDoc();
      final Object? value = await doc.value;
      expect(value, equals({}));
    });

    test('update modifies the document', () async {
      final Doc doc = await Doc.newDoc();
      await doc.update((current) {
        return {'key': 'value'};
      });
      final Object? value = await doc.value;
      expect(value, equals({'key': 'value'}));
    });

    test('save and load preserves data', () async {
      final Doc doc = await Doc.newDoc();
      await doc.update((current) {
        return {'saved': true};
      });
      final Uint8List bytes = await doc.save();
      expect(bytes, isNotEmpty);

      final Doc loadedDoc = await Doc.load(bytes);
      final Object? value = await loadedDoc.value;
      expect(value, equals({'saved': true}));
    });

    test('fork creates a copy', () async {
      final Doc doc = await Doc.newDoc();
      await doc.update((current) {
        return {'original': true};
      });

      final Doc forkedDoc = await doc.fork();
      final Object? value = await forkedDoc.value;
      expect(value, equals({'original': true}));

      // Modify fork, original should not change
      await forkedDoc.update((current) {
        final map = Map<String, Object?>.from(current as Map);
        map['forked'] = true;
        return map;
      });

      final Object? originalValue = await doc.value;
      expect(originalValue, equals({'original': true}));

      final Object? forkedValue = await forkedDoc.value;
      expect(forkedValue, equals({'original': true, 'forked': true}));
    });

    test('merge combines changes', () async {
      final Doc doc1 = await Doc.newDoc();
      await doc1.update((current) => {'doc1': true});

      final Doc doc2 = await doc1.fork();
      await doc2.update((current) {
        final map = Map<String, Object?>.from(current as Map);
        map['doc2'] = true;
        return map;
      });

      await doc1.merge(doc2);
      final Object? value = await doc1.value;

      expect(value, containsPair('doc1', true));
      expect(value, containsPair('doc2', true));
    });
  });
}
