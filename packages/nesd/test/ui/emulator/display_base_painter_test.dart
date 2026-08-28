import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/display.dart';
import 'package:nesd/ui/emulator/emulator_painters.dart';
import 'package:nesd/ui/emulator/video_filter/crt_filter_settings.dart';
import 'package:nesd/ui/emulator/video_filter/shader_frame_painter.dart';
import 'package:nesd/ui/emulator/video_filter/video_filter.dart';

Future<ui.Image> _image() {
  final completer = Completer<ui.Image>();

  ui.decodeImageFromPixels(
    Uint8List(4 * 4 * 4),
    4,
    4,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );

  return completer.future;
}

void main() {
  testWidgets('an active filter with a ready shader selects the shader '
      'painter', (tester) async {
    await tester.runAsync(() async {
      final program = await ui.FragmentProgram.fromAsset('shaders/crt.frag');
      final image = await _image();

      final painter = frameBasePainter(
        image: image,
        filters: const [VideoFilter.crt],
        shaders: {VideoFilter.crt: program.fragmentShader()},
        crtFilter: const CrtFilterSettings(),
      );

      expect(painter, isA<ShaderFramePainter>());
      expect((painter as ShaderFramePainter).parameters, [0.35, 0.25, 0.0]);
    });
  });

  testWidgets('a pending shader falls back to the plain painter', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final painter = frameBasePainter(
        image: await _image(),
        filters: const [VideoFilter.crt],
        shaders: const {},
        crtFilter: const CrtFilterSettings(),
      );

      expect(painter, isA<CpuFramePainter>());
    });
  });

  testWidgets('filter none selects the plain painter', (tester) async {
    await tester.runAsync(() async {
      final painter = frameBasePainter(
        image: await _image(),
        filters: const [],
        shaders: const {},
        crtFilter: const CrtFilterSettings(),
      );

      expect(painter, isA<CpuFramePainter>());
    });
  });

  testWidgets('with both filters enabled the CPU path applies crt only', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final crt = await ui.FragmentProgram.fromAsset('shaders/crt.frag');
      final smooth = await ui.FragmentProgram.fromAsset('shaders/smooth.frag');

      final painter = frameBasePainter(
        image: await _image(),
        filters: const [VideoFilter.smooth, VideoFilter.crt],
        shaders: {
          VideoFilter.smooth: smooth.fragmentShader(),
          VideoFilter.crt: crt.fragmentShader(),
        },
        crtFilter: const CrtFilterSettings(),
      );

      expect(painter, isA<ShaderFramePainter>());
      expect((painter as ShaderFramePainter).parameters, [0.35, 0.25, 0.0]);
    });
  });

  testWidgets('crt pending falls back to the smooth filter', (tester) async {
    await tester.runAsync(() async {
      final smooth = await ui.FragmentProgram.fromAsset('shaders/smooth.frag');

      final painter = frameBasePainter(
        image: await _image(),
        filters: const [VideoFilter.smooth, VideoFilter.crt],
        shaders: {VideoFilter.smooth: smooth.fragmentShader()},
        crtFilter: const CrtFilterSettings(),
      );

      expect(painter, isA<ShaderFramePainter>());
      expect((painter as ShaderFramePainter).parameters, isEmpty);
    });
  });
}
