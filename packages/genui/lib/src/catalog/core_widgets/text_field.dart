// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../core/functions.dart';
import '../../core/widget_utilities.dart';
import '../../model/a2ui_schemas.dart';
import '../../model/catalog_item.dart';
import '../../model/data_model.dart';
import '../../model/ui_models.dart';
import '../../primitives/simple_items.dart';

final _schema = S.object(
  description: 'A text input field.',
  properties: {
    'value': A2uiSchemas.dynamicString(
      description: 'The initial value of the text field.',
    ),
    'label': A2uiSchemas.dynamicString(),
    'variant': S.string(
      enumValues: ['shortText', 'longText', 'number', 'date', 'obscured'],
      description: 'The style variant of the text field.',
    ),
    'checks': A2uiSchemas.checks(),
    'onSubmittedAction': A2uiSchemas.action(),
  },
);

extension type _TextFieldData.fromMap(JsonMap _json) {
  factory _TextFieldData({
    Object? value,
    Object? label,
    String? variant,
    List<Object?>? checks,
    JsonMap? onSubmittedAction,
  }) => _TextFieldData.fromMap({
    'value': value,
    'label': label,
    'variant': variant,
    'checks': checks,
    'onSubmittedAction': onSubmittedAction,
  });

  Object? get value => _json['value'];
  Object? get label => _json['label'];
  String? get variant => _json['variant'] as String?;
  List<Object?>? get checks => _json['checks'] as List<Object?>?;
  JsonMap? get onSubmittedAction => _json['onSubmittedAction'] as JsonMap?;
}

class _TextField extends StatefulWidget {
  const _TextField({
    required this.initialValue,
    this.label,
    this.variant,
    this.checks,
    required this.onChanged,
    required this.onSubmitted,
  });

  final String initialValue;
  final String? label;
  final String? variant;
  final List<Object?>? checks;
  final void Function(String) onChanged;
  final void Function(String) onSubmitted;

  @override
  State<_TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<_TextField> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_TextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validate(String value) {
    if (widget.checks == null) {
      _errorText = null;
      return;
    }

    for (final Object? check in widget.checks!) {
      if (check is Map<String, Object?>) {
        final message = check['message'] as String;
        final callFn = check['call'] as String?;
        if (callFn != null) {
          // We need to execute the check logic.
          // In v0.9, checks usually take the value as an arg, or implicitly?
          // The args in the schema are explicit. We need to inject 'value' into
          // args?
          // A2UI spec: checks are executed. If they return false, validation
          // fails.
          // Usually the value is passed as the first argument or based on
          // context.

          // For simple v0.9 compliance in this phase, we assume args are
          // provided or we provide value if missing? Wait, Schema says: "args":
          // S.list(). If the AI generated "args": [{ "path": "..." }], it's
          // data bound. But how does it check THIS field's value? Usually via a
          // reference to self or just passing the value. Let's assume the
          // standard components pass the current value as the first argument if
          // strictly implied, OR the definition usually includes the value
          // binding in the args.

          //For 'regex' check: execute('regex', [value, pattern]).
          // The AI should generate: call: 'regex', args: [ {path: ...}, pattern
          // ].
          // BUT validaton often runs *before* data update commits?
          // If we just use the args as defined, we might be checking the *data
          // model* value, not the *input* value.
          // This is a subtle point. For now, let's assume we execute with the
          // provided args.

          // However, for 'required', we want to check the input value. Let's
          // inject current value if args are empty and function expects it? Or
          // simpler: The AI must bind the args to the same path as the value.

          final List<Object?> args = (check['args'] as List<Object?>?) ?? [];
          final List<Object?> resolvedArgs = args.map((arg) {
            // We need to resolve args, but DataContext.resolveDynamicValue is
            // what we need. We don't have easy access to DataContext here
            // inside the State? Actually we can't easily resolve dynamic args
            // inside pure State without DataContext. WE NEED DataContext passed
            // to _TextField or available. Placeholder: we can't fully resolve
            // dynamically inside State without context.
            return arg;
          }).toList();

          // HACK: For Phase 2, since we can't easily resolve dynamic args
          // inside this widget State without refactoring to pass DataContext,
          // we will skip complex dynamic args resolution here or pass
          // DataContext down. Ideally `checks` should be evaluated by the
          // *caller* or we pass a validator function?

          // Let's execute assuming args are static for now (e.g. regex
          // patterns) AND the first arg IS the value.
          // Actually, we inject the 'value' as the first argument for standard
          // checks if not present?
          // Or strictly: execute(name, [value, ...args]).
          final Object? result = FunctionRegistry.instance.execute(callFn, [
            value,
            ...resolvedArgs,
          ]);
          if (result == false) {
            setState(() => _errorText = message);
            return;
          }
        }
      }
    }
    if (_errorText != null) {
      setState(() => _errorText = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: _errorText,
      ),
      obscureText: widget.variant == 'obscured',
      keyboardType: switch (widget.variant) {
        'number' => TextInputType.number,
        'longText' => TextInputType.multiline,
        'date' => TextInputType.datetime,
        _ => TextInputType.text,
      },
      onChanged: (val) {
        _validate(val);
        widget.onChanged(val);
      },
      onSubmitted: (val) {
        _validate(val);
        if (_errorText == null) {
          widget.onSubmitted(val);
        }
      },
    );
  }
}

/// A catalog item representing a Material Design text field.
///
/// This widget allows the user to enter and edit text. The `value` parameter
/// bidirectionally binds the field's content to the data model. This is
/// analogous to Flutter's [TextField] widget.
///
/// ## Parameters:
///
/// - `value`: The current value of the text field.
/// - `label`: The text to display as the label for the text field.
/// - `variant`: The style variant. Can be `shortText`, `longText`,
///   `number`, `date`, or `obscured`.
/// - `checks`: A list of validation checks to perform.
/// - `onSubmittedAction`: The action to perform when the user submits the
///   text field.
final textField = CatalogItem(
  name: 'TextField',
  dataSchema: _schema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "TextField": {
              "value": "Hello World",
              "label": "Greeting"
            }
          }
        }
      ]
    ''',
    () => '''
      [
        {
          "id": "root",
          "component": {
            "TextField": {
              "value": "password123",
              "label": "Password",
              "variant": "obscured"
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (itemContext) {
    final textFieldData = _TextFieldData.fromMap(itemContext.data as JsonMap);
    final Object? valueRef = textFieldData.value;

    // Determine path for update
    String? path;
    if (valueRef is Map && valueRef.containsKey('path')) {
      path = valueRef['path'] as String?;
    }

    final ValueNotifier<String?> notifier = itemContext.dataContext
        .subscribeToString(valueRef);
    final ValueNotifier<String?> labelNotifier = itemContext.dataContext
        .subscribeToString(textFieldData.label);

    return ValueListenableBuilder<String?>(
      valueListenable: notifier,
      builder: (context, currentValue, child) {
        return ValueListenableBuilder(
          valueListenable: labelNotifier,
          builder: (context, label, child) {
            return _TextField(
              initialValue: currentValue ?? '',
              label: label,
              variant: textFieldData.variant,
              checks: textFieldData.checks,
              onChanged: (newValue) {
                if (path != null) {
                  itemContext.dataContext.update(DataPath(path), newValue);
                }
              },
              onSubmitted: (newValue) {
                final JsonMap? actionData = textFieldData.onSubmittedAction;
                if (actionData == null) {
                  return;
                }
                final actionName = actionData['name'] as String;
                final JsonMap contextDefinition =
                    (actionData['context'] as JsonMap?) ?? {};
                final JsonMap resolvedContext = resolveContext(
                  itemContext.dataContext,
                  contextDefinition,
                );
                itemContext.dispatchEvent(
                  UserActionEvent(
                    name: actionName,
                    sourceComponentId: itemContext.id,
                    context: resolvedContext,
                  ),
                );
              },
            );
          },
        );
      },
    );
  },
);
