@Tags(['screenshots'])
library;

import 'dart:io';
import 'dart:ui' hide Color, Size;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nesd/ui/theme/base.dart';

const _output =
    'android/app/src/main/play/listings/en-US/graphics/feature-graphic';

void _stripAlpha(File file) {
  final rendered = img.decodePng(file.readAsBytesSync());

  if (rendered == null) {
    throw StateError('Expected a PNG at ${file.path}');
  }

  file.writeAsBytesSync(img.encodePng(rendered.convert(numChannels: 3)));
}

void main() {
  testWidgets('feature graphic', (tester) async {
    tester.view
      ..devicePixelRatio = 1.0
      ..physicalSize = const Size(1024, 500);

    addTearDown(tester.view.reset);

    final fontLoader = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'));

    await fontLoader.load();

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(size: Size(1024, 500)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: _FeatureGraphic(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await _waitUntil(tester, () {
      final images = tester.widgetList<RawImage>(find.byType(RawImage));

      return images.isNotEmpty && images.every((i) => i.image != null);
    });

    Directory(_output).createSync(recursive: true);

    final file = File('$_output/feature.png');

    await tester.runAsync(() async {
      final element = tester.element(find.byType(_FeatureGraphic));

      var renderObject = element.renderObject!;

      while (!renderObject.isRepaintBoundary) {
        renderObject = renderObject.parent!;
      }

      final layer = renderObject.debugLayer! as OffsetLayer;
      final image = await layer.toImage(renderObject.paintBounds);
      final bytes = await image.toByteData(format: ImageByteFormat.png);

      file.writeAsBytesSync(bytes!.buffer.asUint8List());
    });

    _stripAlpha(file);

    final decoded = img.decodePng(file.readAsBytesSync())!;

    expect(decoded.width, 1024);
    expect(decoded.height, 500);
    expect(decoded.numChannels, 3);
  });
}

Future<void> _fixAsync(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );

  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _waitUntil(
  WidgetTester tester,
  bool Function() condition, {
  int maxAttempts = 20,
}) async {
  for (var attempt = 0; attempt < maxAttempts && !condition(); attempt++) {
    await _fixAsync(tester);
  }

  expect(
    condition(),
    isTrue,
    reason: 'condition not met after $maxAttempts fixAsync cycles',
  );
}

class _FeatureGraphic extends StatelessWidget {
  const _FeatureGraphic();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.black, nesdRed[900]!],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 72, vertical: 48),
        child: Row(
          children: [
            Image.asset('assets/logo.png', width: 320, height: 320),
            const SizedBox(width: 56),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'NESd',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontSize: 96,
                      height: 1,
                      fontVariations: [FontVariation.weight(700)],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 120,
                    height: 6,
                    decoration: BoxDecoration(
                      color: nesdRed[500],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'A cycle-accurate NES emulator',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white70,
                      fontSize: 32,
                      fontVariations: [FontVariation.weight(500)],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
