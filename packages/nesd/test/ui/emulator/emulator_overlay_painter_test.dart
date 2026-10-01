import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/ui/emulator/emulator_painters.dart';

class _MockCanvas extends Mock implements Canvas {}

EmulatorOverlayPainter _painter({
  bool paused = true,
  bool frameStepping = false,
  int frame = 0,
}) => EmulatorOverlayPainter(
  scale: 1,
  pixelAspectRatio: 1,
  showBorder: false,
  paused: paused,
  fastForward: false,
  rewind: false,
  frameStepping: frameStepping,
  frame: frame,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const size = Size(256, 240);

  setUpAll(() {
    registerFallbackValue(Rect.zero);
    registerFallbackValue(Paint());
    registerFallbackValue(Offset.zero);
    registerFallbackValue(
      (ui.ParagraphBuilder(ui.ParagraphStyle())..addText('x')).build(),
    );
  });

  test('a plain pause dims the screen and draws no badge', () {
    final canvas = _MockCanvas();

    _painter().paint(canvas, size);

    verify(() => canvas.drawRect(Offset.zero & size, any())).called(1);
    verifyNever(() => canvas.drawParagraph(any(), any()));
  });

  test('frame stepping draws the badge instead of dimming', () {
    final canvas = _MockCanvas();

    _painter(frameStepping: true, frame: 42).paint(canvas, size);

    verifyNever(() => canvas.drawRect(any(), any()));
    verify(() => canvas.drawParagraph(any(), any())).called(2);
  });

  test('the badge stays while a step runs', () {
    final canvas = _MockCanvas();

    _painter(paused: false, frameStepping: true).paint(canvas, size);

    verify(() => canvas.drawParagraph(any(), any())).called(2);
    verifyNever(() => canvas.drawRect(any(), any()));
  });

  test('no badge while running normally', () {
    final canvas = _MockCanvas();

    _painter(paused: false).paint(canvas, size);

    verifyNever(() => canvas.drawParagraph(any(), any()));
    verifyNever(() => canvas.drawRect(any(), any()));
  });

  test('the badge names the frame', () {
    expect(frameSteppingLabel(12345), 'Frame 12345');
  });

  test('repaints when the frame or stepping state changes', () {
    final painter = _painter(frameStepping: true, frame: 1);

    expect(
      painter.shouldRepaint(_painter(frameStepping: true, frame: 1)),
      isFalse,
    );
    expect(
      painter.shouldRepaint(_painter(frameStepping: true, frame: 2)),
      isTrue,
    );
    expect(painter.shouldRepaint(_painter(frame: 1)), isTrue);
  });
}
