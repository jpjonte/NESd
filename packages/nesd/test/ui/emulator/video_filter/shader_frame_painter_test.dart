import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/video_filter/crt_filter_settings.dart';
import 'package:nesd/ui/emulator/video_filter/shader_frame_painter.dart';
import 'package:nesd/ui/emulator/video_filter/video_filter.dart';

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

Future<ui.Image> _imageFromPixels(Uint8List pixels, int width, int height) {
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
    sourceRect: ui.Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    ),
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

Future<Uint8List> _paintFilterMode(
  String asset, {
  required VideoFilter filter,
  required CrtFilterSettings crtFilter,
  required ui.Image image,
  required ui.Size sourceSize,
  required ui.Size outputSize,
}) async {
  final program = await ui.FragmentProgram.fromAsset(asset);
  final shader = program.fragmentShader()
    ..setFloat(0, outputSize.width)
    ..setFloat(1, outputSize.height)
    ..setImageSampler(0, image);

  configureVideoFilterShader(
    shader,
    filter: filter,
    sourceWidth: sourceSize.width,
    sourceHeight: sourceSize.height,
    crtFilter: crtFilter,
  );

  final recorder = ui.PictureRecorder();

  ui.Canvas(
    recorder,
  ).drawRect(ui.Offset.zero & outputSize, ui.Paint()..shader = shader);

  final output = await recorder.endRecording().toImage(
    outputSize.width.toInt(),
    outputSize.height.toInt(),
  );
  final data = await output.toByteData();

  return data!.buffer.asUint8List();
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

  testWidgets('crt scanlines repeat per source row, '
      'darkening every row boundary', (tester) async {
    await tester.runAsync(() async {
      final image = await _patternImage(
        8,
        4,
        [255, 255, 255, 255],
        [255, 255, 255, 255],
      ); // uniform white

      final pixels = await _paint(
        'shaders/crt.frag',
        [1.0, 0.0, 0.0], // full scanline intensity, no mask, no curvature
        image,
        const ui.Size(64, 32),
      );

      final boundaryPixel = _getPixel(pixels, 32, 16, 64);
      final centerPixel = _getPixel(pixels, 32, 20, 64);

      final boundaryBrightness =
          boundaryPixel[0] + boundaryPixel[1] + boundaryPixel[2];
      final centerBrightness = centerPixel[0] + centerPixel[1] + centerPixel[2];

      expect(boundaryBrightness, lessThan(300));
      expect(centerBrightness, greaterThan(boundaryBrightness + 300));
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

  testWidgets('crt shader in image-filter mode reads the engine-written '
      'input size and repeats scanlines per source row', (tester) async {
    await tester.runAsync(() async {
      final image = await _patternImage(
        64,
        32,
        [255, 255, 255, 255],
        [255, 255, 255, 255],
      ); // uniform white, already at output resolution

      final pixels = await _paintFilterMode(
        'shaders/crt.frag',
        filter: VideoFilter.crt,
        crtFilter: const CrtFilterSettings(
          scanlineIntensity: 1,
          maskStrength: 0,
        ),
        image: image,
        sourceSize: const ui.Size(8, 4),
        outputSize: const ui.Size(64, 32),
      );

      final boundaryPixel = _getPixel(pixels, 32, 16, 64);
      final centerPixel = _getPixel(pixels, 32, 20, 64);

      final boundaryBrightness =
          boundaryPixel[0] + boundaryPixel[1] + boundaryPixel[2];
      final centerBrightness = centerPixel[0] + centerPixel[1] + centerPixel[2];

      expect(boundaryBrightness, lessThan(300));
      expect(centerBrightness, greaterThan(boundaryBrightness + 300));
    });
  });

  testWidgets('smooth shader in image-filter mode samples the upscaled '
      'input at source-texel centers, preserving regions and seam', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final image = await _patternImage(
        64,
        32,
        [255, 0, 0, 255],
        [0, 255, 0, 255],
      );

      final pixels = await _paintFilterMode(
        'shaders/smooth.frag',
        filter: VideoFilter.smooth,
        crtFilter: const CrtFilterSettings(),
        image: image,
        sourceSize: const ui.Size(4, 2),
        outputSize: const ui.Size(64, 32),
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

  testWidgets('smooth output fed into the crt pass keeps the smoothed '
      'seam and adds scanlines', (tester) async {
    await tester.runAsync(() async {
      final upscaled = await _patternImage(
        64,
        32,
        [255, 0, 0, 255],
        [0, 255, 0, 255],
      );

      final smoothed = await _paintFilterMode(
        'shaders/smooth.frag',
        filter: VideoFilter.smooth,
        crtFilter: const CrtFilterSettings(),
        image: upscaled,
        sourceSize: const ui.Size(4, 2),
        outputSize: const ui.Size(64, 32),
      );

      final smoothedImage = await _imageFromPixels(smoothed, 64, 32);

      final chained = await _paintFilterMode(
        'shaders/crt.frag',
        filter: VideoFilter.crt,
        crtFilter: const CrtFilterSettings(
          scanlineIntensity: 1,
          maskStrength: 0,
        ),
        image: smoothedImage,
        sourceSize: const ui.Size(4, 2),
        outputSize: const ui.Size(64, 32),
      );

      final boundary = _getPixel(chained, 8, 16, 64);
      final center = _getPixel(chained, 8, 24, 64);

      expect(
        boundary[0] + boundary[1] + boundary[2],
        lessThan(center[0] + center[1] + center[2] - 150),
      );

      final seamLeft = _getPixel(chained, 31, 24, 64);
      final seamRight = _getPixel(chained, 32, 24, 64);

      expect(seamLeft[0], greaterThan(60));
      expect(seamRight[1], greaterThan(60));
    });
  });
}
