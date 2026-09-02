import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

const _red = [255, 0, 0, 255];
const _blue = [0, 0, 255, 255];

Future<ui.Image> _gridImage(List<String> rows, {int scale = 1}) {
  final height = rows.length * scale;
  final width = rows.first.length * scale;
  final pixels = Uint8List(width * height * 4);

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final index = (y * width + x) * 4;
      final cell = rows[y ~/ scale][x ~/ scale];

      pixels.setRange(index, index + 4, cell == '#' ? _red : _blue);
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

List<String> _diagonalGrid(int size) => [
  for (var y = 0; y < size; y++)
    [
      for (var x = 0; x < size; x++)
        if (x < y) '#' else '.',
    ].join(),
];

Future<Uint8List> _render(
  String asset, {
  required ui.Image image,
  required ui.Size outputSize,
  ui.Size? sourceSize,
}) async {
  final source =
      sourceSize ?? ui.Size(image.width.toDouble(), image.height.toDouble());

  final program = await ui.FragmentProgram.fromAsset(asset);
  final shader = program.fragmentShader()
    ..setFloat(0, outputSize.width)
    ..setFloat(1, outputSize.height)
    ..setFloat(2, source.width)
    ..setFloat(3, source.height)
    ..setFloat(4, 0)
    ..setFloat(5, 0)
    ..setFloat(6, source.width)
    ..setFloat(7, source.height)
    ..setImageSampler(0, image);

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

List<int> _getPixel(Uint8List pixels, int x, int y, int width) {
  final index = (y * width + x) * 4;

  return [
    pixels[index],
    pixels[index + 1],
    pixels[index + 2],
    pixels[index + 3],
  ];
}

void main() {
  testWidgets('ramps the staircase of a diagonal edge', (tester) async {
    await tester.runAsync(() async {
      final image = await _gridImage(_diagonalGrid(8));

      final pixels = await _render(
        'shaders/xbr.frag',
        image: image,
        outputSize: const ui.Size(64, 64),
      );

      final filled = _getPixel(pixels, 24, 31, 64);

      expect(filled[0], greaterThan(200));
      expect(filled[2], lessThan(50));

      final kept = _getPixel(pixels, 31, 24, 64);

      expect(kept[2], greaterThan(200));
      expect(kept[0], lessThan(50));
    });
  });

  testWidgets('ramps the staircase in image-filter mode, where the input '
      'is already upscaled', (tester) async {
    await tester.runAsync(() async {
      final image = await _gridImage(_diagonalGrid(8), scale: 8);

      final pixels = await _render(
        'shaders/xbr.frag',
        image: image,
        sourceSize: const ui.Size(8, 8),
        outputSize: const ui.Size(64, 64),
      );

      final filled = _getPixel(pixels, 24, 31, 64);

      expect(filled[0], greaterThan(200));
      expect(filled[2], lessThan(50));
    });
  });

  testWidgets('joins a one texel wide diagonal line', (tester) async {
    await tester.runAsync(() async {
      final image = await _gridImage([
        '......',
        '.#....',
        '..#...',
        '...#..',
        '....#.',
        '......',
      ]);

      final pixels = await _render(
        'shaders/xbr.frag',
        image: image,
        outputSize: const ui.Size(36, 36),
      );

      final joint = _getPixel(pixels, 12, 11, 36);

      expect(joint[0], greaterThan(200));
      expect(joint[2], lessThan(50));
    });
  });

  testWidgets('leaves a vertical edge crisp', (tester) async {
    await tester.runAsync(() async {
      final image = await _gridImage([for (var y = 0; y < 4; y++) '####....']);

      final pixels = await _render(
        'shaders/xbr.frag',
        image: image,
        outputSize: const ui.Size(60, 30),
      );

      var blended = 0;

      for (var y = 0; y < 30; y++) {
        for (var x = 0; x < 60; x++) {
          final pixel = _getPixel(pixels, x, y, 60);

          final pure =
              (pixel[0] > 250 && pixel[2] < 5) ||
              (pixel[0] < 5 && pixel[2] > 250);

          if (!pure) {
            blended++;
          }
        }
      }

      expect(blended, 0);
    });
  });
}
