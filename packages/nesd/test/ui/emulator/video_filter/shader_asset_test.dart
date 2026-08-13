import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('both shader programs compile and load', (tester) async {
    await tester.runAsync(() async {
      final crt = await ui.FragmentProgram.fromAsset('shaders/crt.frag');
      final smooth = await ui.FragmentProgram.fromAsset('shaders/smooth.frag');

      expect(crt.fragmentShader(), isNotNull);
      expect(smooth.fragmentShader(), isNotNull);
    });
  });
}
