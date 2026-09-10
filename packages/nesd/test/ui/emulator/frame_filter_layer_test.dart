import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/display.dart';
import 'package:nesd/ui/emulator/overscan.dart';
import 'package:nesd/ui/emulator/overscan_crop.dart';
import 'package:nesd/ui/emulator/video_filter/crt_filter_settings.dart';
import 'package:nesd/ui/emulator/video_filter/video_filter.dart';

void main() {
  ui.ImageFilter identityFilter(ui.FragmentShader shader) =>
      ui.ImageFilter.matrix(Matrix4.identity().storage);

  Future<ui.FragmentShader> loadShader(WidgetTester tester) async {
    late ui.FragmentShader shader;

    await tester.runAsync(() async {
      final program = await ui.FragmentProgram.fromAsset('shaders/crt.frag');

      shader = program.fragmentShader();
    });

    return shader;
  }

  Future<ui.Image> loadImage(WidgetTester tester) async {
    late ui.Image image;

    await tester.runAsync(() async {
      final pixels = Uint8List(4 * 4 * 4)..fillRange(0, 4 * 4 * 4, 0xff);

      final completer = Completer<ui.Image>();

      ui.decodeImageFromPixels(
        pixels,
        4,
        4,
        ui.PixelFormat.rgba8888,
        completer.complete,
      );

      image = await completer.future;
    });

    return image;
  }

  testWidgets('wraps a filtered child in the composed chain', (tester) async {
    final shader = await loadShader(tester);
    final image = await loadImage(tester);

    await tester.pumpWidget(
      frameFilterLayer(
        child: RawImage(image: image),
        imageWidth: 256,
        imageHeight: 240,
        filters: const [VideoFilter.crt],
        shaders: {VideoFilter.crt: shader},
        crtFilter: const CrtFilterSettings(),
        shaderFilterSupported: true,
        imageFilterFactory: identityFilter,
      ),
    );

    expect(
      find.descendant(
        of: find.byType(ImageFiltered),
        matching: find.byType(RawImage),
      ),
      findsOneWidget,
    );
  });

  testWidgets('leaves the child unfiltered when no filter is active', (
    tester,
  ) async {
    final image = await loadImage(tester);

    await tester.pumpWidget(
      frameFilterLayer(
        child: RawImage(image: image),
        imageWidth: 256,
        imageHeight: 240,
        filters: const [],
        shaders: const {},
        crtFilter: const CrtFilterSettings(),
        shaderFilterSupported: true,
        imageFilterFactory: identityFilter,
      ),
    );

    expect(find.byType(ImageFiltered), findsNothing);
    expect(find.byType(RawImage), findsOneWidget);
  });

  testWidgets('crops overscan before the filter sees the frame', (
    tester,
  ) async {
    final image = await loadImage(tester);

    await tester.pumpWidget(
      frameFilterLayer(
        child: RawImage(image: image),
        imageWidth: 256,
        imageHeight: 240,
        filters: const [],
        shaders: const {},
        crtFilter: const CrtFilterSettings(),
        shaderFilterSupported: true,
        imageFilterFactory: identityFilter,
        overscan: const Overscan(),
      ),
    );

    expect(find.byType(OverscanCrop), findsOneWidget);
  });
}
