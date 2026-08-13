import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/video_filter/shader_frame_painter.dart';

Future<ui.Image> _patternImage(
  int width,
  int height,
  List<int> leftRgba,
  List<int> rightRgba,
) {
  final pixels = Uint8List(width * height * 4);
  final mid = width ~/ 2;

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final idx = (y * width + x) * 4;
      if (x < mid) {
        pixels.setRange(idx, idx + 4, leftRgba);
      } else {
        pixels.setRange(idx, idx + 4, rightRgba);
      }
    }
  }

  final completer = Completer<ui.Image>();

  ui.decodeImageFromPixels(
    pixels,
    width,
    height,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );

  return completer.future;
}

Future<Uint8List> _paint(
  String asset,
  List<double> parameters,
  ui.Image image,
  ui.Size outputSize,
) async {
  final program = await ui.FragmentProgram.fromAsset(asset);
  final painter = ShaderFramePainter(
    image: image,
    shader: program.fragmentShader(),
    parameters: parameters,
  );

  final recorder = ui.PictureRecorder();

  painter.paint(ui.Canvas(recorder), outputSize);

  final output = await recorder.endRecording().toImage(
    outputSize.width.toInt(),
    outputSize.height.toInt(),
  );
  final data = await output.toByteData();

  return data!.buffer.asUint8List();
}

List<int> _getPixel(Uint8List pixels, int x, int y, int width) {
  final idx = (y * width + x) * 4;
  return [pixels[idx], pixels[idx + 1], pixels[idx + 2], pixels[idx + 3]];
}

void main() {
  testWidgets('crt shader with high intensity darkens row edges '
      '(discriminates output-height uniform swap)', (tester) async {
    await tester.runAsync(() async {
      final image = await _patternImage(
        8,
        4,
        [255, 0, 0, 255],
        [0, 255, 0, 255],
      ); // Red left, green right
      final pixels = await _paint(
        'shaders/crt.frag',
        [0.8, 0.0, 0.0], // scanlineIntensity=0.8, curvature=0, mask=0
        image,
        const ui.Size(64, 32),
      );

      final edgePixel = _getPixel(pixels, 4, 0, 64);
      final midPixel = _getPixel(pixels, 4, 4, 64);

      final edgeBrightness = edgePixel[0] + edgePixel[1] + edgePixel[2];
      final midBrightness = midPixel[0] + midPixel[1] + midPixel[2];

      expect(midBrightness, greaterThan(edgeBrightness + 40));
    });
  });

  testWidgets('smooth shader upscales left/right regions preserving seam '
      '(discriminates source/output width uniform swaps)', (tester) async {
    await tester.runAsync(() async {
      final image = await _patternImage(
        4,
        2,
        [255, 0, 0, 255],
        [0, 255, 0, 255],
      );
      final pixels = await _paint(
        'shaders/smooth.frag',
        const [],
        image,
        const ui.Size(64, 32),
      );

      final leftPixel = _getPixel(pixels, 8, 16, 64);
      expect(leftPixel[0], greaterThan(200));
      expect(leftPixel[1], lessThan(50));

      final rightPixel = _getPixel(pixels, 56, 16, 64);
      expect(rightPixel[0], lessThan(50));
      expect(rightPixel[1], greaterThan(200));

      final seam1Pixel = _getPixel(pixels, 28, 16, 64);
      expect(seam1Pixel[0], greaterThan(100));

      final seam2Pixel = _getPixel(pixels, 32, 16, 64);
      expect(seam2Pixel[1], greaterThan(100));
    });
  });
}
