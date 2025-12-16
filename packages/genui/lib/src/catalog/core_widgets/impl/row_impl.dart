// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../../model/catalog_item.dart';
import '../../../model/data_model.dart';
import '../../../primitives/simple_items.dart';
import 'widget_helpers.dart';

extension type RowData.fromMap(JsonMap _json) {
  factory RowData({
    Object? children,
    String? distribution,
    String? alignment,
  }) => RowData.fromMap({
    'children': children,
    'distribution': distribution,
    'alignment': alignment,
  });

  Object? get children => _json['children'];
  String? get distribution => _json['distribution'] as String?;
  String? get alignment => _json['alignment'] as String?;
}

MainAxisAlignment _parseMainAxisAlignment(String? alignment) {
  switch (alignment) {
    case 'start':
      return MainAxisAlignment.start;
    case 'center':
      return MainAxisAlignment.center;
    case 'end':
      return MainAxisAlignment.end;
    case 'spaceBetween':
      return MainAxisAlignment.spaceBetween;
    case 'spaceAround':
      return MainAxisAlignment.spaceAround;
    case 'spaceEvenly':
      return MainAxisAlignment.spaceEvenly;
    default:
      return MainAxisAlignment.start;
  }
}

CrossAxisAlignment _parseCrossAxisAlignment(String? alignment) {
  switch (alignment) {
    case 'start':
      return CrossAxisAlignment.start;
    case 'center':
      return CrossAxisAlignment.center;
    case 'end':
      return CrossAxisAlignment.end;
    case 'stretch':
      return CrossAxisAlignment.stretch;
    case 'baseline':
      return CrossAxisAlignment.baseline;
    default:
      return CrossAxisAlignment.start;
  }
}

Widget rowBuilder(CatalogItemContext itemContext) {
  final rowData = RowData.fromMap(itemContext.data as JsonMap);
  return ComponentChildrenBuilder(
    childrenData: rowData.children,
    binder: itemContext.binder,
    buildChild: itemContext.buildChild,
    getComponent: itemContext.getComponent,
    explicitListBuilder: (childIds, buildChild, getComponent, dataContext) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final CrossAxisAlignment crossAxisAlignment =
              _parseCrossAxisAlignment(rowData.alignment);
          final CrossAxisAlignment effectiveCrossAxisAlignment =
              crossAxisAlignment == CrossAxisAlignment.stretch &&
                  constraints.maxHeight == double.infinity
              ? CrossAxisAlignment.start
              : crossAxisAlignment;

          return Row(
            mainAxisAlignment: _parseMainAxisAlignment(rowData.distribution),
            crossAxisAlignment: effectiveCrossAxisAlignment,
            mainAxisSize: MainAxisSize.min,
            children: childIds
                .map(
                  (componentId) => buildWeightedChild(
                    componentId: componentId,
                    dataContext: dataContext,
                    buildChild: buildChild,
                    component: getComponent(componentId)!,
                  ),
                )
                .toList(),
          );
        },
      );
    },
    templateListWidgetBuilder: (context, list, componentId, dataBinding) {
      if (list is! List) {
        return const SizedBox.shrink();
      }
      return LayoutBuilder(
        builder: (context, constraints) {
          final CrossAxisAlignment crossAxisAlignment =
              _parseCrossAxisAlignment(rowData.alignment);
          final CrossAxisAlignment effectiveCrossAxisAlignment =
              crossAxisAlignment == CrossAxisAlignment.stretch &&
                  constraints.maxHeight == double.infinity
              ? CrossAxisAlignment.start
              : crossAxisAlignment;

          return Row(
            mainAxisAlignment: _parseMainAxisAlignment(rowData.distribution),
            crossAxisAlignment: effectiveCrossAxisAlignment,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < list.length; i++) ...[
                buildWeightedChild(
                  componentId: componentId,
                  dataContext: itemContext.dataContext.nested(
                    DataPath('$dataBinding/$i'),
                  ),
                  buildChild: itemContext.buildChild,
                  component: itemContext.getComponent(componentId),
                ),
              ],
            ],
          );
        },
      );
    },
  );
}
