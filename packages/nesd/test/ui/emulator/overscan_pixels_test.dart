import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/emulator_painters.dart';
import 'package:nesd/ui/emulator/overscan.dart';
import 'package:nesd/ui/emulator/video_filter/crt_filter_settings.dart';
import 'package:nesd/ui/emulator/video_filter/shader_frame_painter.dart';
import 'package:nesd/ui/emulator/video_filter/video_filter.dart';

Future<ui.Image> _bandedFrame() {
  final pixels = Uint8List(256 * 240 * 4);

  for (var y = 0; y < 240; y++) {
    final edge = y < 8 || y >= 232;

    for (var x = 0; x < 256; x++) {
      final offset = (y * 256 + x) * 4;

      pixels[offset] = edge ? 255 : 0;
      pixels[offset + 1] = edge ? 0 : 255;
      pixels[offset + 2] = 0;
      pixels[offset + 3] = 255;
    }
  }

  final completer = Completer<ui.Image>();

  ui.decodeImageFromPixels(
    pixels,
    256,
    240,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );

  return completer.future;
}

Future<Uint8List> _render(CustomPainter painter, ui.Size size) async {
  final recorder = ui.PictureRecorder();

  painter.paint(ui.Canvas(recorder), size);

  final image = await recorder.endRecording().toImage(
    size.width.toInt(),
    size.height.toInt(),
  );

  return (await image.toByteData())!.buffer.asUint8List();
}

int _reddishPixels(Uint8List pixels) {
  var count = 0;

  for (var i = 0; i < pixels.length; i += 4) {
    if (pixels[i] > 128 && pixels[i + 1] < 128) {
      count++;
    }
  }

  return count;
}

void main() {
  const overscan = Overscan();
  const visible = ui.Size(256, 224);

  testWidgets('the CPU painter drops the cropped rows', (tester) async {
    await tester.runAsync(() async {
      final image = await _bandedFrame();

      final pixels = await _render(
        CpuFramePainter(
          image: image,
          sourceRect: overscan.visibleRect(256, 240),
        ),
        visible,
      );

      expect(_reddishPixels(pixels), 0);
    });
  });

  testWidgets('the CPU painter shows the edge rows when nothing is cropped', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final image = await _bandedFrame();

      final pixels = await _render(
        CpuFramePainter(
          image: image,
          sourceRect: Overscan.none.visibleRect(256, 240),
        ),
        const ui.Size(256, 240),
      );

      expect(_reddishPixels(pixels), greaterThan(0));
    });
  });

  testWidgets('the smooth shader samples only the cropped area', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final image = await _bandedFrame();
      final program = await ui.FragmentProgram.fromAsset('shaders/smooth.frag');

      final pixels = await _render(
        ShaderFramePainter(
          image: image,
          shader: program.fragmentShader(),
          parameters: videoFilterUniforms(
            VideoFilter.smooth,
            const CrtFilterSettings(),
          ),
          sourceRect: overscan.visibleRect(256, 240),
        ),
        visible,
      );

      expect(_reddishPixels(pixels), 0);
    });
  });

  testWidgets('curvature cannot pull the cropped rows back into view', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final image = await _bandedFrame();
      final program = await ui.FragmentProgram.fromAsset('shaders/crt.frag');

      final pixels = await _render(
        ShaderFramePainter(
          image: image,
          shader: program.fragmentShader(),
          parameters: videoFilterUniforms(
            VideoFilter.crt,
            const CrtFilterSettings(curvature: 0.25),
          ),
          sourceRect: overscan.visibleRect(256, 240),
        ),
        visible,
      );

      expect(_reddishPixels(pixels), 0);
    });
  });
}
