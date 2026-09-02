import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('all shader programs compile and load', (tester) async {
    await tester.runAsync(() async {
      final crt = await ui.FragmentProgram.fromAsset('shaders/crt.frag');
      final smooth = await ui.FragmentProgram.fromAsset('shaders/smooth.frag');
      final xbr = await ui.FragmentProgram.fromAsset('shaders/xbr.frag');

      expect(crt.fragmentShader(), isNotNull);
      expect(smooth.fragmentShader(), isNotNull);
      expect(xbr.fragmentShader(), isNotNull);
    });
  });
}
