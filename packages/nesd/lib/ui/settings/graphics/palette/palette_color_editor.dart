import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/emulator/input/intents.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_editor_state.dart';

const _channelLabels = ['Red', 'Green', 'Blue'];

int _channelValue(int color, int channel) =>
    (color >> ((2 - channel) * 8)) & 0xff;

int _withChannel(int color, int channel, int value) {
  final shift = (2 - channel) * 8;

  return (color & ~(0xff << shift)) | (value.clamp(0, 255) << shift);
}

String _hex(int color) =>
    '#${color.toRadixString(16).padLeft(6, '0').toUpperCase()}';

final _hexPattern = RegExp(r'^#?([0-9a-fA-F]{6})$');

int? parseHexColor(String text) {
  final match = _hexPattern.firstMatch(text.trim());

  if (match == null) {
    return null;
  }

  return int.parse(match.group(1)!, radix: 16);
}

String _paletteIndexLabel(int index) {
  final hex = index.toRadixString(16).padLeft(2, '0').toUpperCase();

  return 'Color \$$hex';
}

class PaletteColorEditor extends HookConsumerWidget {
  const PaletteColorEditor({required this.state, super.key});

  static const hexKey = Key('paletteHex');

  static Key channelKey(int channel) => ValueKey('paletteChannel$channel');

  final PaletteEditorState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.read(paletteEditorProvider.notifier);
    final color = state.selectedColor;
    final controller = useTextEditingController(text: _hex(color));

    useEffect(() {
      if (parseHexColor(controller.text) != color) {
        controller.text = _hex(color);
      }

      return null;
    }, [color]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Focus(
          skipTraversal: true,
          child: SettingsTile(
            title: Text(_paletteIndexLabel(state.selected)),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  color: Color(0xff000000 | color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    key: hexKey,
                    controller: controller,
                    decoration: const InputDecoration(labelText: 'Hex'),
                    onChanged: (text) {
                      final parsed = parseHexColor(text);

                      if (parsed == null) {
                        return;
                      }

                      editor.setColor(
                        state.selected,
                        parsed,
                        source: EditSource.hex(state.selected),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        for (var channel = 0; channel < 3; channel++)
          _ChannelSlider(
            channel: channel,
            color: color,
            onChanged: (value) => editor.setColor(
              state.selected,
              _withChannel(color, channel, value),
              source: EditSource.channel(state.selected, channel),
            ),
            onDragStart: editor.beginEdit,
            onDragEnd: editor.endEdit,
            onReset: () => editor.revertColor(state.selected),
          ),
      ],
    );
  }
}

class _ChannelSlider extends StatelessWidget {
  const _ChannelSlider({
    required this.channel,
    required this.color,
    required this.onChanged,
    required this.onReset,
    required this.onDragStart,
    required this.onDragEnd,
  });

  final int channel;
  final int color;
  final ValueChanged<int> onChanged;
  final VoidCallback onReset;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    final value = _channelValue(color, channel);

    return Actions(
      actions: {
        DecreaseIntent: CallbackAction<DecreaseIntent>(
          onInvoke: (_) => onChanged(value - 1),
        ),
        IncreaseIntent: CallbackAction<IncreaseIntent>(
          onInvoke: (_) => onChanged(value + 1),
        ),
      },
      child: FocusOnHover(
        child: SliderSettingsTile(
          key: PaletteColorEditor.channelKey(channel),
          onChangeStart: (_) => onDragStart(),
          onChangeEnd: (_) => onDragEnd(),
          label: _channelLabels[channel],
          value: value.toDouble(),
          displayValue: '$value',
          max: 255,
          onTap: onReset,
          onChanged: (v) => onChanged(v.round()),
        ),
      ),
    );
  }
}
