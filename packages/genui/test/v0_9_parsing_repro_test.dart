import 'package:flutter_test/flutter_test.dart';
import 'package:genui/src/model/a2ui_message.dart';

void main() {
  test('Parses v0.9 UpdateComponents message', () {
    final json = {
      'updateComponents': {
        'surfaceId': 'test_surface',
        'components': [
          {
            'id': 'root',
            'component': 'Column',
            'children': ['child1']
          },
          {
            'id': 'child1',
            'component': 'Text',
            'text': 'Hello World'
          }
        ]
      }
    };

    try {
      final message = A2uiMessage.fromJson(json);
      expect(message, isA<UpdateComponents>());
      final update = message as UpdateComponents;
      expect(update.components.length, 2);
      expect(update.components[0].id, 'root');
      print('Successfully parsed v0.9 message');
    } catch (e) {
      print('Failed to parse v0.9 message: $e');
      rethrow;
    }
  });

  test('Parses v0.8 UpdateComponents message (just to confirm baseline)', () {
    final json = {
      'updateComponents': {
        'surfaceId': 'test_surface',
        'components': [
          {
            'id': 'root',
            'component': {
              'Column': {
                'children': ['child1']
              }
            }
          }
        ]
      }
    };

    final message = A2uiMessage.fromJson(json);
    expect(message, isA<UpdateComponents>());
    expect((message as UpdateComponents).components[0].id, 'root');
  });
}
