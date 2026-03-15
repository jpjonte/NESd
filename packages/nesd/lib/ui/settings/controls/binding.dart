import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/input/touch/touch_input_config.dart';
import 'package:nesd/ui/settings/controls/input_combination.dart';
import 'package:nesd/util/decorate.dart';

part 'binding.freezed.dart';

enum BindingType { hold, toggle }

@freezed
class Binding with _$Binding {
  const Binding({
    required this.index,
    required this.input,
    required this.action,
    this.type = BindingType.hold,
  });

  @override
  final int index;

  @override
  final InputCombination input;

  @override
  final BindingType type;

  @override
  final InputAction action;

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'input': input.toJson(),
      'action': action.code,
      'type': type.name,
    };
  }
}

typedef Bindings = List<Binding>;

Bindings bindingsFromJson(dynamic json) {
  if (json is Map<String, dynamic>) {
    final bindings = <Binding>[];

    for (final MapEntry(key: code, :value) in json.entries) {
      try {
        final action = InputAction.fromCode(code);

        if (action == null) {
          continue;
        }

        final inputs = _inputsFromJson(value);

        for (var i = 0; i < inputs.length; i++) {
          final input = inputs[i];

          if (input == null) {
            continue;
          }

          bindings.add(Binding(index: i, input: input, action: action));
        }

        // catch errors to ignore invalid actions
        // ignore: avoid_catching_errors
      } on StateError {
        // ignore invalid actions
      }
    }

    return bindings;
  }

  if (json is! List<dynamic>) {
    return defaultBindings;
  }

  final bindings = <Binding>[];

  for (final e in json) {
    try {
      final binding = _bindingFromJson(e as Map<String, dynamic>);

      if (binding != null) {
        bindings.add(binding);
      }
    } on Exception {
      // ignore invalid bindings
    }
  }

  return bindings;
}

Binding? _bindingFromJson(Map<String, dynamic> json) {
  final action = InputAction.fromCode(json['action'] as String?);

  if (action == null) {
    return null;
  }

  return Binding(
    index: json['index'] as int,
    input: InputCombination.fromJson(json['input'] as Map<String, dynamic>),
    action: action,
    type: BindingType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => BindingType.hold,
    ),
  );
}

List<InputCombination?> _inputsFromJson(dynamic value) {
  if (value is! List) {
    return [
      if (value != null)
        InputCombination.fromJson(value as Map<String, dynamic>)
      else
        null,
    ];
  }

  return [
    for (final e in value)
      decorate(e, (e) => InputCombination.fromJson(e as Map<String, dynamic>)),
  ];
}

List<TouchInputConfig> narrowTouchInputConfigsFromJson(dynamic json) {
  if (json is! List || json.isEmpty) {
    return defaultPortraitConfig;
  }

  return touchInputConfigsFromJson(json);
}

List<TouchInputConfig> wideTouchInputConfigsFromJson(dynamic json) {
  if (json is! List || json.isEmpty) {
    return defaultLandscapeConfig;
  }

  return touchInputConfigsFromJson(json);
}

List<TouchInputConfig> touchInputConfigsFromJson(List<dynamic> json) {
  return json
      .map((e) => TouchInputConfig.fromJson(e as Map<String, dynamic>))
      .whereType<TouchInputConfig>()
      .toList();
}
