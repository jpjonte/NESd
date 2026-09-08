import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/emulator/nes_palette_provider.dart';

class PalettePreview extends ConsumerWidget {
  const PalettePreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(nesPaletteProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          for (var row = 0; row < 4; row++)
            Row(
              children: [
                for (var column = 0; column < 16; column++)
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ColoredBox(
                        color: _colorOf(palette[row * 16 + column]),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Color _colorOf(int word) => Color(
    0xff000000 |
        ((word & 0xff) << 16) |
        (word & 0x0000ff00) |
        ((word >> 16) & 0xff),
  );
}
