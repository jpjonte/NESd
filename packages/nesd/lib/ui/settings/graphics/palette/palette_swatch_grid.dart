import 'package:flutter/material.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';

class PaletteSwatchGrid extends StatelessWidget {
  const PaletteSwatchGrid({
    required this.colors,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  static Key swatchKey(int index) => ValueKey('paletteSwatch$index');

  final List<int> colors;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < 4; row++)
          Row(
            children: [
              for (var column = 0; column < 16; column++)
                Expanded(
                  child: _Swatch(
                    index: row * 16 + column,
                    colors: colors,
                    selected: selected,
                    highlight: theme.colorScheme.primary,
                    onSelected: onSelected,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.index,
    required this.colors,
    required this.selected,
    required this.highlight,
    required this.onSelected,
  });

  final int index;
  final List<int> colors;
  final int selected;
  final Color highlight;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selected;

    return FocusOnHover(
      child: InkWell(
        key: PaletteSwatchGrid.swatchKey(index),
        onTap: () => onSelected(index),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xff000000 | colors[index]),
              border: Border.all(
                color: isSelected ? highlight : Colors.transparent,
                width: 3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
