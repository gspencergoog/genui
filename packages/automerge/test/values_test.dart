import 'package:automerge/automerge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await RustLib.init();
  });

  group('Values', () {
    test('update handles primitive types', () async {
      final Doc doc = await Doc.newDoc();
      await doc.update((current) {
        return {
          'string': 'hello',
          'int': 42,
          'true': true,
          'false': false,
          'double': 3.14,
          'null': null,
        };
      });

      final value = await doc.value as Map<String, Object?>;
      expect(value['string'], equals('hello'));
      expect(value['int'], equals(42));
      expect(value['true'], equals(true));
      expect(value['false'], equals(false));
      expect(value['double'], equals(3.14));
      expect(value['null'], isNull);
    });

    test('update handles nested maps', () async {
      final Doc doc = await Doc.newDoc();
      await doc.update((current) {
        return {
          'nested': {
            'key': 'value',
            'deep': {'answer': 42},
          },
        };
      });

      final value = await doc.value as Map<String, Object?>;
      final nested = value['nested'] as Map<String, Object?>;
      expect(nested['key'], equals('value'));

      final deep = nested['deep'] as Map<String, Object?>;
      expect(deep['answer'], equals(42));
    });

    test('update handles lists', () async {
      final Doc doc = await Doc.newDoc();
      await doc.update((current) {
        return {
          'list': [1, 2, 3, 'four'],
        };
      });

      final value = await doc.value as Map<String, Object?>;
      final list = value['list'] as List<Object?>;
      expect(list, equals([1, 2, 3, 'four']));
    });

    test('update handles complex nested structures', () async {
      final Doc doc = await Doc.newDoc();
      await doc.update((current) {
        return {
          'users': [
            {'id': 1, 'name': 'Alice'},
            {'id': 2, 'name': 'Bob'},
          ],
        };
      });

      final value = await doc.value as Map<String, Object?>;
      final users = value['users'] as List<Object?>;
      expect(users.length, equals(2));

      final alice = users[0] as Map<String, Object?>;
      expect(alice['name'], equals('Alice'));
    });

    test('reconcile replaces entire document state', () async {
      final Doc doc = await Doc.newDoc();
      await doc.update((_) => {'initial': 'state'});

      await doc.reconcile({'new': 'state'});

      final Object? value = await doc.value;
      expect(value, equals({'new': 'state'}));
    });
  });
}
