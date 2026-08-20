import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'robot.dart';

void main() {
  testWidgets('screenshot captures at the requested pixel ratio', (
    tester,
  ) async {
    final r = Robot(tester);

    await r.pumpApp(logicalSize: const Size(360, 800), devicePixelRatio: 3);

    final file = File(
      '${Directory.systemTemp.createTempSync('nesd_shot').path}/shot.png',
    );

    await r.screenshot(file.path, pixelRatio: 3);

    final decoded = img.decodePng(file.readAsBytesSync());

    expect(decoded, isNotNull);
    expect(decoded!.width, 1080);
    expect(decoded.height, 2400);
  });

  testWidgets('pumpApp still defaults to the desktop viewport', (tester) async {
    final r = Robot(tester);

    await r.pumpApp();

    expect(
      tester.view.physicalSize,
      const Size(1920, 1080) * tester.view.devicePixelRatio,
    );
  });
}
