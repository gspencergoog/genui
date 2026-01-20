// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:collection/collection.dart';

import '../primitives/simple_items.dart';
import 'a2ui_protocol.dart';

/// A callback that is called when events are sent.
typedef SendEventsCallback =
    void Function(String surfaceId, List<UiEvent> events);

/// A callback that is called when an event is dispatched.
typedef DispatchEventCallback = void Function(UiEvent event);

/// A data object that represents a user interaction event in the UI.
///
/// This is used to send information from the app to the AI about user
/// actions, such as tapping a button or entering text.
extension type UiEvent.fromMap(JsonMap _json) {
  /// The ID of the surface that this event originated from.
  String get surfaceId => _json[surfaceIdKey] as String;

  /// The ID of the widget that triggered the event.
  String get widgetId => _json['widgetId'] as String;

  /// The type of event that was triggered (e.g., 'onChanged', 'onTap').
  String get eventType => _json['eventType'] as String;

  /// Whether this event should trigger an event.
  ///
  /// The event can be a submission to the AI or
  /// a change in the UI state that should be handled by
  /// host of the surface.
  bool get isAction => _json['isAction'] as bool;

  /// The value associated with the event, if any (e.g., the text in a
  /// `TextField`, or the value of a `Checkbox`).
  Object? get value => _json['value'];

  /// The timestamp of when the event occurred.
  DateTime get timestamp => DateTime.parse(_json['timestamp'] as String);

  /// Converts this event to a map, suitable for JSON serialization.
  JsonMap toMap() => _json;
}

/// A UI event that represents a user action.
///
/// This is used for events that should trigger a submission to the AI, such as
/// tapping a button.
extension type UserActionEvent.fromMap(JsonMap _json) implements UiEvent {
  /// Creates a [UserActionEvent] from a set of properties.
  UserActionEvent({
    String? surfaceId,
    required String name,
    required String sourceComponentId,
    DateTime? timestamp,
    JsonMap? context,
  }) : _json = {
         if (surfaceId != null) surfaceIdKey: surfaceId,
         'name': name,
         'sourceComponentId': sourceComponentId,
         'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
         'isAction': true,
         'context': context ?? {},
       };

  String get name => _json['name'] as String;
  String get sourceComponentId => _json['sourceComponentId'] as String;
  JsonMap get context => _json['context'] as JsonMap;
}

/// A data object that represents the entire UI definition.
///
/// This is the root object that defines a complete UI to be rendered.
class UiDefinition {
  /// The ID of the surface that this UI belongs to.
  final String surfaceId;

  /// The ID of the root widget in the UI tree.
  final String? rootComponentId;

  /// The ID of the catalog to use for rendering this surface.
  final String? catalogId;

  /// The global styles to apply to the UI.
  final JsonMap? styles;

  /// A map of all widget definitions in the UI, keyed by their ID.
  Map<String, Component> get components => UnmodifiableMapView(_components);
  final Map<String, Component> _components;

  /// Creates a [UiDefinition].
  UiDefinition({
    required this.surfaceId,
    this.rootComponentId,
    this.catalogId,
    this.styles,
    Map<String, Component> components = const {},
  }) : _components = components;

  /// Creates a copy of this [UiDefinition] with the given fields replaced.
  UiDefinition copyWith({
    String? rootComponentId,
    String? catalogId,
    JsonMap? styles,
    Map<String, Component>? components,
  }) {
    return UiDefinition(
      surfaceId: surfaceId,
      rootComponentId: rootComponentId ?? this.rootComponentId,
      catalogId: catalogId ?? this.catalogId,
      styles: styles ?? this.styles,
      components: components ?? _components,
    );
  }

  /// Converts this object to a JSON map.
  JsonMap toJson() {
    return {
      surfaceIdKey: surfaceId,
      if (rootComponentId != null) 'rootComponentId': rootComponentId,
      if (catalogId != null) 'catalogId': catalogId,
      if (styles != null) 'styles': styles,
      'components': components.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }

  /// Converts a UI definition into a blob of text
  String asContextDescriptionText() {
    final String text = jsonEncode(this);
    return 'A user interface is shown with the following content:\n$text.';
  }
}

/// A component in the UI.
final class Component {
  /// Creates a [Component].
  const Component({
    required this.id,
    required this.componentProperties,
    this.weight,
    this.version = A2uiProtocolVersion.v0_8,
  });

  /// Creates a [Component] from a JSON map.
  factory Component.fromJson(
    JsonMap json, {
    A2uiProtocolVersion version = A2uiProtocolVersion.v0_8,
  }) {
    switch (version) {
      case A2uiProtocolVersion.v0_8:
        return Component._fromV08Json(json);
      case A2uiProtocolVersion.v0_9:
        return Component._fromV09Json(json);
    }
  }

  factory Component._fromV08Json(JsonMap json) {
    final id = json['id'] as String;
    final int? weight = (json['weight'] as num?)?.toInt();
    final Map<String, Object?> props = Map.of(json);
    props.remove('id');
    props.remove('weight');
    return Component(
      id: id,
      componentProperties: props,
      weight: weight,
      version: A2uiProtocolVersion.v0_8,
    );
  }

  factory Component._fromV09Json(JsonMap json) {
    final id = json['id'] as String;
    final int? weight = (json['weight'] as num?)?.toInt();
    final Map<String, Object?> props =
        (json['props'] as Map<String, Object?>?) ?? <String, Object?>{};
    return Component(
      id: id,
      componentProperties: props,
      weight: weight,
      version: A2uiProtocolVersion.v0_9,
    );
  }

  /// The unique ID of the component.
  final String id;

  /// The properties of the component.
  final JsonMap componentProperties;

  /// The weight of the component, used for layout in Row/Column.
  final int? weight;

  /// The protocol version used by this component.
  final A2uiProtocolVersion version;

  /// Converts this object to a JSON map.
  JsonMap toJson() {
    switch (version) {
      case A2uiProtocolVersion.v0_8:
        return {
          'id': id,
          if (weight != null) 'weight': weight,
          ...componentProperties,
        };
      case A2uiProtocolVersion.v0_9:
        return {
          'id': id,
          if (weight != null) 'weight': weight,
          'props': componentProperties,
        };
    }
  }

  /// The type of the component.
  String get type {
    switch (version) {
      case A2uiProtocolVersion.v0_8:
        return (props['component'] as Map).keys.first as String;
      case A2uiProtocolVersion.v0_9:
        return componentProperties['component'] as String;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Component &&
      id == other.id &&
      weight == other.weight &&
      version == other.version &&
      const DeepCollectionEquality().equals(
        componentProperties,
        other.componentProperties,
      );

  @override
  int get hashCode => Object.hash(
    id,
    weight,
    version,
    const DeepCollectionEquality().hash(componentProperties),
  );
}
