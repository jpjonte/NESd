import 'dart:async';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> loadAppFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final materialIcons =
      '$flutterRoot/bin/cache/artifacts/material_fonts/'
      'MaterialIcons-Regular.otf';

  await loadTestFont('Inter', ['assets/fonts/Inter-Regular.ttf']);
  await loadTestFont('MaterialIcons', [materialIcons]);
}

Future<void> loadTestFont(String family, List<String> fontFiles) async {
  await TestWidgetsFlutterBinding.instance.runAsync(() async {
    final systemFonts = PaintingBinding.instance.systemFonts;
    final delivered = Completer<void>();

    var pending = fontFiles.length;

    void onFontsChange() {
      pending--;

      // only return when all fonts have been loaded
      if (pending == 0) {
        delivered.complete();
      }
    }

    systemFonts.addListener(onFontsChange);

    try {
      final fontLoader = FontLoader(family);

      for (final fontFile in fontFiles) {
        fontLoader.addFont(rootBundle.load(fontFile));
      }

      await fontLoader.load();
      await delivered.future;
    } finally {
      systemFonts.removeListener(onFontsChange);
    }
  });
}
