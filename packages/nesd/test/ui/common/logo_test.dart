import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/common/logo.dart';

void main() {
  ui.Image? paintedLogo(WidgetTester tester) =>
      tester.widget<RawImage>(find.byType(RawImage)).image;

  Future<void> pumpLogo(WidgetTester tester) => tester.pumpWidget(
    const MaterialApp(home: Image(image: AssetImage(logoAsset))),
  );

  setUp(() {
    imageCache
      ..clear()
      ..clearLiveImages();
  });

  testWidgets('the logo is not painted on its first frame uncached', (
    tester,
  ) async {
    await pumpLogo(tester);

    expect(paintedLogo(tester), isNull);
  });

  testWidgets('precacheLogo makes the logo paint on its first frame', (
    tester,
  ) async {
    await tester.runAsync(precacheLogo);

    await pumpLogo(tester);

    expect(paintedLogo(tester), isNotNull);
  });
}
