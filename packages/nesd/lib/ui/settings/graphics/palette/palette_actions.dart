import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/nes/ppu/palette/pal_file.dart';

class PaletteActions {
  const PaletteActions();

  Future<Uri?> exportPalette(String name, List<int> rgb) => FilePicker.saveFile(
    bytes: writePalFile(rgb),
    fileName: '$name.pal',
    type: FileType.custom,
    allowedExtensions: ['pal'],
  );
}

final paletteActionsProvider = Provider<PaletteActions>(
  (ref) => const PaletteActions(),
);
