// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

import 'package:genui/test/fake_content_generator.dart';
import 'package:integration_test/integration_test.dart';
import 'package:travel_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Initial UI test', () {
    testWidgets('send a request and verify the UI', (tester) async {
      final mockContentGenerator = FakeContentGenerator();
      for (final Map<String, Object> messageJson in _baliResponse) {
        mockContentGenerator.addA2uiMessage(
          A2uiProtocol.fromVersion(
            A2uiProtocolVersion.v0_9,
          ).parseJson(messageJson),
        );
      }

      runApp(app.TravelApp(contentGenerator: mockContentGenerator));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'Plan a trip to Bali');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Great! I can help you plan a fantastic trip to Bali. To '
          'get started, what kind of experience are you looking for?',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(
        find.text('Cultural Immersion', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Plan My Trip', findRichText: true), findsOneWidget);
    });
  });
}

final List<Map<String, Object>> _baliResponse = [
  {
    'createSurface': {
      'surfaceId': 'bali_trip_planning_intro',
      'catalogId': 'example.com:travel_v0',
    },
  },
  {
    'updateComponents': {
      'surfaceId': 'bali_trip_planning_intro',
      'components': [
        {
          'id': 'root',
          'props': {
            'component': 'Column',
            'children': {
              'explicitList': ['welcome_text', 'bali_carousel', 'trip_filters'],
            },
            'spacing': {'literalNumber': 16},
            'crossAxisAlignment': {'literalString': 'start'},
            'mainAxisAlignment': {'literalString': 'start'},
          },
        },
        {
          'id': 'welcome_text',
          'props': {
            'component': 'Text',
            'text': {
              'literalString':
                  'Great! I can help you plan a fantastic trip to Bali. To '
                  'get started, what kind of experience are you looking for?',
            },
          },
        },
        {
          'id': 'bali_carousel',
          'props': {
            'component': 'TravelCarousel',
            'items': {
              'explicitList': [
                {
                  'imageChildId': 'bali_memorial_image',
                  'title': {'literalString': 'Cultural Immersion'},
                },
                {
                  'imageChildId': 'nyepi_festival_image',
                  'title': {'literalString': 'Festivals and Traditions'},
                },
                {
                  'imageChildId': 'kata_noi_beach_image',
                  'title': {'literalString': 'Beach Relaxation'},
                },
              ],
            },
          },
        },
        {
          'id': 'bali_memorial_image',
          'props': {
            'component': 'Image',
            'fit': {'literalString': 'cover'},
            'location': {
              'literalString': 'assets/travel_images/bali_memorial.jpg',
            },
          },
        },
        {
          'id': 'nyepi_festival_image',
          'props': {
            'component': 'Image',
            'fit': {'literalString': 'cover'},
            'location': {
              'literalString': 'assets/travel_images/nyepi_festival_bali.jpg',
            },
          },
        },
        {
          'id': 'kata_noi_beach_image',
          'props': {
            'component': 'Image',
            'fit': {'literalString': 'cover'},
            'location': {
              'literalString':
                  'assets/travel_images/kata_noi_beach_phuket_thailand.jpg',
            },
          },
        },
        {
          'id': 'trip_filters',
          'props': {
            'component': 'FilterChipGroup',
            'submitLabel': {'literalString': 'Plan My Trip'},
            'children': {
              'explicitList': [
                'travel_style_chip',
                'budget_chip',
                'duration_chip',
              ],
            },
          },
        },
        {
          'id': 'travel_style_chip',
          'props': {
            'component': 'OptionsFilterChip',
            'iconChild': 'travel_icon_hiking',
            'options': {
              'literalArray': [
                'Relaxation',
                'Adventure',
                'Culture',
                'Family Fun',
                'Romantic Getaway',
              ],
            },
            'chipLabel': {'literalString': 'Travel Style'},
          },
        },
        {
          'id': 'travel_icon_hiking',
          'props': {
            'component': 'TravelIcon',
            'icon': {'literalString': 'hiking'},
          },
        },
        {
          'id': 'budget_chip',
          'props': {
            'component': 'OptionsFilterChip',
            'options': {
              'literalArray': ['Economy', 'Mid-range', 'Luxury'],
            },
            'iconChild': 'travel_icon_wallet',
            'chipLabel': {'literalString': 'Budget'},
          },
        },
        {
          'id': 'travel_icon_wallet',
          'props': {
            'component': 'TravelIcon',
            'icon': {'literalString': 'wallet'},
          },
        },
        {
          'id': 'duration_chip',
          'props': {
            'component': 'OptionsFilterChip',
            'chipLabel': {'literalString': 'Duration'},
            'options': {
              'literalArray': ['3-5 Days', '1 Week', '10+ Days'],
            },
            'iconChild': 'travel_icon_calendar',
          },
        },
        {
          'id': 'travel_icon_calendar',
          'props': {
            'component': 'TravelIcon',
            'icon': {'literalString': 'calendar'},
          },
        },
      ],
    },
  },
];
