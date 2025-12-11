// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../../model/catalog_item.dart';
import '../../../model/data_model.dart';
import '../../../primitives/simple_items.dart';
import 'widget_helpers.dart';

extension type ListData.fromMap(JsonMap _json) {
  factory ListData({
    required Object? children,
    String? direction,
    String? alignment,
  }) => ListData.fromMap({
    'children': children,
    'direction': direction,
    'alignment': alignment,
  });

  Object? get children => _json['children'];
  String? get direction => _json['direction'] as String?;
  String? get alignment => _json['alignment'] as String?;
}

Widget listBuilder(CatalogItemContext itemContext) {
  final listData = ListData.fromMap(itemContext.data as JsonMap);
  final Axis direction = listData.direction == 'horizontal'
      ? Axis.horizontal
      : Axis.vertical;
  return ComponentChildrenBuilder(
    childrenData: listData.children,
    dataContext: itemContext.dataContext,
    buildChild: itemContext.buildChild,
    getComponent: itemContext.getComponent,
    explicitListBuilder: (childIds, buildChild, getComponent, dataContext) {
      return ListView(
        shrinkWrap: true,
        scrollDirection: direction,
        children: childIds.map((id) => buildChild(id, dataContext)).toList(),
      );
    },
    templateListWidgetBuilder:
        (context, Object? data, componentId, dataBinding) {
          if (data is! Map<String, Object?>) {
            return const SizedBox.shrink();
          }
          final List<Object?> values = data.values.toList();
          final List<String> keys = data.keys.toList();
          return ListView.builder(
            shrinkWrap: true,
            scrollDirection: direction,
            itemCount: values.length,
            itemBuilder: (context, index) {
              final DataContext itemDataContext = itemContext.dataContext
                  .nested(DataPath('$dataBinding/${keys[index]}'));
              return itemContext.buildChild(componentId, itemDataContext);
            },
          );
        },
  );
}
