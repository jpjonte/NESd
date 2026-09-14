import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/input/input_hint_resolver.dart';
import 'package:nesd/ui/emulator/input/input_method.dart';
import 'package:nesd/ui/settings/controls/input_combination.dart';

const _borderRadius = BorderRadius.all(Radius.circular(6));
const _padding = EdgeInsets.symmetric(horizontal: 10, vertical: 4);
const _minHeight = 32.0;
const _touchMinHeight = 44.0;
const _iconSize = 16.0;
const _spacing = 12.0;
const _runSpacing = 6.0;
const _fontSize = 11.0;

const _capBorderRadius = BorderRadius.all(Radius.circular(4));
const _capPadding = EdgeInsets.symmetric(horizontal: 6, vertical: 1);
const _capSpacing = 3.0;
const _bindingSpacing = 4.0;

@immutable
class InputHint {
  const InputHint({
    required this.label,
    this.actions = const [],
    this.icon,
    this.onPressed,
  });

  final String label;

  final List<InputAction> actions;

  final IconData? icon;

  final VoidCallback? onPressed;
}

const navigateHint = InputHint(
  actions: [inputUp, previousInput, inputDown, nextInput],
  label: 'Navigate',
);

const selectHint = InputHint(actions: [confirm], label: 'Select');

const backHint = InputHint(actions: [cancel], label: 'Back');

class InputHintBar extends ConsumerWidget {
  const InputHintBar({
    required this.hints,
    this.color,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final List<InputHint> hints;

  final Color? color;

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolver = ref.watch(inputHintResolverProvider);

    final chips = [for (final hint in hints) ?_chip(hint, resolver)];

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return _HintPaletteScope(
      palette: _HintPalette(color ?? Theme.of(context).colorScheme.onSurface),
      child: Padding(
        padding: padding,
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: _spacing,
          runSpacing: _runSpacing,
          children: chips,
        ),
      ),
    );
  }

  Widget? _chip(InputHint hint, InputHintResolver resolver) {
    if (resolver.method == InputMethod.touch) {
      if (hint.onPressed == null) {
        return null;
      }

      return _HintChip(
        prompt: hint.icon == null ? null : _HintIcon(hint.icon!),
        label: hint.label,
        minHeight: _touchMinHeight,
        onPressed: hint.onPressed,
      );
    }

    final bindings = {...hint.actions.map(resolver.bindingFor).nonNulls};

    if (hint.actions.isNotEmpty && bindings.isEmpty) {
      return null;
    }

    return _HintChip(
      prompt: bindings.isEmpty ? null : _BindingPrompt(bindings.toList()),
      label: hint.label,
      onPressed: hint.onPressed,
    );
  }
}

String keyCapLabel(LogicalKeyboardKey key) => switch (key) {
  LogicalKeyboardKey.arrowLeft => '←',
  LogicalKeyboardKey.arrowRight => '→',
  LogicalKeyboardKey.arrowUp => '↑',
  LogicalKeyboardKey.arrowDown => '↓',
  LogicalKeyboardKey.escape => 'Esc',
  LogicalKeyboardKey.space => 'Space',
  LogicalKeyboardKey.control ||
  LogicalKeyboardKey.controlLeft ||
  LogicalKeyboardKey.controlRight => 'Ctrl',
  LogicalKeyboardKey.shift ||
  LogicalKeyboardKey.shiftLeft ||
  LogicalKeyboardKey.shiftRight => 'Shift',
  LogicalKeyboardKey.alt ||
  LogicalKeyboardKey.altLeft ||
  LogicalKeyboardKey.altRight => 'Alt',
  LogicalKeyboardKey.meta ||
  LogicalKeyboardKey.metaLeft ||
  LogicalKeyboardKey.metaRight => _metaLabel(),
  _ => key.keyLabel,
};

String _metaLabel() => switch (defaultTargetPlatform) {
  TargetPlatform.macOS => 'Cmd',
  TargetPlatform.windows => 'Win',
  _ => 'Meta',
};

@immutable
class _HintPalette {
  _HintPalette(Color base)
    : text = base,
      label = base.withAlpha(0xb3),
      fill = base.withAlpha(0x1f),
      capFill = base.withAlpha(0x1a),
      capBorder = base.withAlpha(0x61);

  final Color text;
  final Color label;
  final Color fill;
  final Color capFill;
  final Color capBorder;
}

class _HintPaletteScope extends InheritedWidget {
  const _HintPaletteScope({required this.palette, required super.child});

  final _HintPalette palette;

  static _HintPalette of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_HintPaletteScope>()!.palette;

  @override
  bool updateShouldNotify(_HintPaletteScope oldWidget) =>
      palette.text != oldWidget.palette.text;
}

class _HintChip extends StatelessWidget {
  const _HintChip({
    required this.prompt,
    required this.label,
    this.minHeight = _minHeight,
    this.onPressed,
  });

  final Widget? prompt;
  final String label;
  final double minHeight;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = _HintPaletteScope.of(context);

    return Material(
      color: palette.fill,
      borderRadius: _borderRadius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: _borderRadius,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Padding(
            padding: _padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (prompt case final prompt?) ...[
                  prompt,
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(color: palette.label, fontSize: _fontSize),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HintIcon extends StatelessWidget {
  const _HintIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      color: _HintPaletteScope.of(context).text,
      size: _iconSize,
    );
  }
}

class _BindingPrompt extends StatelessWidget {
  const _BindingPrompt(this.bindings);

  final List<InputCombination> bindings;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: _bindingSpacing,
      children: [for (final binding in bindings) _Caps(_capLabels(binding))],
    );
  }

  static List<String> _capLabels(InputCombination binding) => switch (binding) {
    KeyboardInputCombination() => binding.sortedKeys.map(keyCapLabel).toList(),
    GamepadInputCombination(:final inputs) => [
      for (final input in inputs) input.label ?? input.id,
    ],
  };
}

class _Caps extends StatelessWidget {
  const _Caps(this.labels);

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: _capSpacing,
      children: [
        for (final (i, label) in labels.indexed) ...[
          if (i > 0) const _CapText('+'),
          _Cap(label),
        ],
      ],
    );
  }
}

class _Cap extends StatelessWidget {
  const _Cap(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = _HintPaletteScope.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.capFill,
        border: Border.fromBorderSide(BorderSide(color: palette.capBorder)),
        borderRadius: _capBorderRadius,
      ),
      child: Padding(padding: _capPadding, child: _CapText(label)),
    );
  }
}

class _CapText extends StatelessWidget {
  const _CapText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: _HintPaletteScope.of(context).text,
        fontSize: _fontSize,
        fontVariations: const [FontVariation.weight(700)],
      ),
    );
  }
}
