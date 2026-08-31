import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';

void main() {
  test('carries the palette table', () {
    final palette = Uint32List(nesPaletteLength);

    palette[7] = 0xff123456;

    final command = SetPaletteCommand(palette: palette);

    expect(command.palette.length, equals(nesPaletteLength));
    expect(command.palette[7], equals(0xff123456));
  });
}
