// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../../core/data_binder.dart';
import '../../../model/catalog_item.dart';
import '../../../primitives/simple_items.dart';

extension type TabsData.fromMap(JsonMap _json) {
  factory TabsData({required List<JsonMap> tabItems}) =>
      TabsData.fromMap({'tabItems': tabItems});

  List<JsonMap> get tabItems => (_json['tabItems'] as List).cast<JsonMap>();
}

Widget tabsBuilder(CatalogItemContext itemContext) {
  final DataBinder binder = itemContext.binder;
  final tabsData = TabsData.fromMap(itemContext.data as JsonMap);
  return DefaultTabController(
    length: tabsData.tabItems.length,
    child: Column(
      children: [
        TabBar(
          tabs: tabsData.tabItems.map((tabItem) {
            final ValueNotifier<String?> titleNotifier = binder
                .subscribeToString(tabItem['title'] as JsonMap);
            return ValueListenableBuilder<String?>(
              valueListenable: titleNotifier,
              builder: (context, title, child) {
                return Tab(text: title ?? '');
              },
            );
          }).toList(),
        ),
        Builder(
          builder: (context) {
            final TabController tabController = DefaultTabController.of(
              context,
            );
            return AnimatedBuilder(
              animation: tabController,
              builder: (context, child) {
                return itemContext.buildChild(
                  tabsData.tabItems[tabController.index]['child'] as String,
                );
              },
            );
          },
        ),
      ],
    ),
  );
}
