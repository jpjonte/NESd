import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> loadAppFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final materialIcons =
      '$flutterRoot/bin/cache/artifacts/material_fonts/'
      'MaterialIcons-Regular.otf';

  await _loadFont('Inter', ['assets/fonts/Inter-Regular.ttf']);
  await _loadFont('MaterialIcons', [materialIcons]);
}

Future<void> _loadFont(String family, List<String> fontFiles) async {
  final fontLoader = FontLoader(family);

  for (final fontFile in fontFiles) {
    fontLoader.addFont(rootBundle.load(fontFile));
  }

  await fontLoader.load();
}
