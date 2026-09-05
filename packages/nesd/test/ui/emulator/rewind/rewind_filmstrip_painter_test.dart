import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/ui/emulator/rewind/rewind_filmstrip_painter.dart';
import 'package:nesd/ui/emulator/rewind/rewind_scrub_controller.dart';

class _MockCanvas extends Mock implements Canvas {}

const _filmHeight = 120.0;
const _cellWidth = _filmHeight * 256 / 240;

const _size = Size(1280, _filmHeight + rewindFilmstripRulerHeight);

const _labelStyle = TextStyle(fontSize: 11);

const _captureInterval = 4;
const _frameRate = 60;

const _stride = 15;

Future<ui.Image> _image() {
  final completer = Completer<ui.Image>();

  ui.decodeImageFromPixels(
    Uint8List(4),
    1,
    1,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );

  return completer.future;
}

Future<RewindScrubState> _state({
  required int oldestSequence,
  required int newestSequence,
  required List<int> thumbnailSequences,
  int? cursorSequence,
  int captureInterval = _captureInterval,
  int frameRate = _frameRate,
}) async => RewindScrubState(
  open: true,
  cursorSequence: cursorSequence ?? newestSequence,
  oldestSequence: oldestSequence,
  newestSequence: newestSequence,
  captureInterval: captureInterval,
  frameRate: frameRate,
  thumbnails: [for (final _ in thumbnailSequences) await _image()],
  thumbnailSequences: thumbnailSequences,
  settled: true,
);

double _secondsBack(RewindScrubState state, int sequence) =>
    (state.newestSequence - sequence) * state.captureInterval / state.frameRate;

RewindFilmstripPainter _painter(RewindScrubState state) =>
    RewindFilmstripPainter(
      state: state,
      secondsBack: (sequence) => _secondsBack(state, sequence),
      labelStyle: _labelStyle,
    );

_MockCanvas _paint(RewindScrubState state, {Size size = _size}) {
  final canvas = _MockCanvas();

  _painter(state).paint(canvas, size);

  return canvas;
}

List<Offset> _tickOffsets(_MockCanvas canvas) => verify(
  () => canvas.drawParagraph(any(), captureAny()),
).captured.cast<Offset>();

ui.Paragraph _emptyParagraph() =>
    (ui.ParagraphBuilder(ui.ParagraphStyle())..addText('')).build()
      ..layout(const ui.ParagraphConstraints(width: 0));

List<Rect> _imageRects(_MockCanvas canvas) => verify(
  () => canvas.drawImageRect(any(), any(), captureAny(), any()),
).captured.cast<Rect>();

List<Rect> _rectsPainted(_MockCanvas canvas, Color color) {
  final captured = verify(
    () => canvas.drawRect(captureAny(), captureAny()),
  ).captured;

  return [
    for (var i = 0; i < captured.length; i += 2)
      if ((captured[i + 1]! as Paint).color.toARGB32() == color.toARGB32())
        captured[i]! as Rect,
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    registerFallbackValue(Rect.zero);
    registerFallbackValue(Offset.zero);
    registerFallbackValue(Paint());
    registerFallbackValue(_emptyParagraph());
    registerFallbackValue(await _image());
  });

  test('draws one cell per thumbnail in the visible window', () async {
    final state = await _state(
      oldestSequence: 0,
      newestSequence: 60,
      thumbnailSequences: const [0, 15, 30, 45, 60],
    );

    final rects = _imageRects(_paint(state));

    expect(rects, hasLength(5));

    expect(rects.last.center.dx, moreOrLessEquals(_size.width / 2));
    expect(rects[3].center.dx, moreOrLessEquals(_size.width / 2 - _cellWidth));
    expect(rects.first.height, moreOrLessEquals(_filmHeight - 4));
  });

  test('slides the film as the cursor moves between thumbnails', () async {
    final state = await _state(
      oldestSequence: 0,
      newestSequence: 60,
      thumbnailSequences: const [0, 15, 30, 45, 60],
      cursorSequence: 60 - _stride ~/ 2,
    );

    final rects = _imageRects(_paint(state));

    expect(
      rects.last.center.dx,
      moreOrLessEquals(_size.width / 2 + _cellWidth * 7 / _stride),
    );
  });

  test(
    'draws a placeholder for a slot the ring has no thumbnail for',
    () async {
      final state = await _state(
        oldestSequence: 0,
        newestSequence: 45,
        thumbnailSequences: const [0, 15],
      );

      final canvas = _paint(state);

      expect(_imageRects(canvas), hasLength(2));

      final placeholders = _rectsPainted(canvas, Colors.white10);

      expect(placeholders, hasLength(2));
      expect(
        placeholders.map((rect) => rect.center.dx),
        everyElement(lessThan(_size.width / 2 + 1)),
      );
    },
  );

  test('draws nothing for slots outside the timeline', () async {
    final state = await _state(
      oldestSequence: 0,
      newestSequence: 15,
      thumbnailSequences: const [0, 15],
    );

    final canvas = _paint(state);

    expect(_imageRects(canvas), hasLength(2));
    expect(_rectsPainted(canvas, Colors.white10), isEmpty);
  });

  test('marks the cursor as unsettled while the walk travels', () async {
    final settled = await _state(
      oldestSequence: 0,
      newestSequence: 60,
      thumbnailSequences: const [0, 15, 30, 45, 60],
    );

    expect(_rectsPainted(_paint(settled), Colors.white), hasLength(1));

    final travelling = settled.copyWith(settled: false);

    expect(_rectsPainted(_paint(travelling), Colors.white), isEmpty);
    expect(_rectsPainted(_paint(travelling), Colors.orange), hasLength(1));
  });

  test('labels every visible cell under the film', () async {
    final state = await _state(
      oldestSequence: 0,
      newestSequence: 60,
      thumbnailSequences: const [0, 15, 30, 45, 60],
    );

    final offsets = _tickOffsets(_paint(state));

    expect(offsets, hasLength(5));
    expect(
      offsets.map((offset) => offset.dy),
      everyElement(greaterThanOrEqualTo(_filmHeight)),
    );
    expect(
      offsets.map((offset) => offset.dx).toList(),
      orderedEquals(offsets.map((offset) => offset.dx).toList()..sort()),
    );
  });

  test('labels whole seconds when the cells are a second apart', () async {
    final state = await _state(
      oldestSequence: 0,
      newestSequence: 60,
      thumbnailSequences: const [0, 15, 30, 45, 60],
    );

    final painter = _painter(state);

    expect(painter.tickLabel(60), '-0s');
    expect(painter.tickLabel(45), '-1s');
    expect(painter.tickLabel(0), '-4s');
  });

  test('labels PAL cells with the fraction of a second they span', () async {
    final state = await _state(
      oldestSequence: 0,
      newestSequence: 240,
      thumbnailSequences: const [0, 60, 120, 180, 240],
      captureInterval: 1,
      frameRate: 50,
    );

    final painter = _painter(state);

    expect(painter.tickLabel(240), '-0.0s');
    expect(painter.tickLabel(180), '-1.2s');
    expect(painter.tickLabel(120), '-2.4s');
    expect(painter.tickLabel(60), '-3.6s');
    expect(painter.tickLabel(0), '-4.8s');
  });

  test('repaints only when the session state changes', () async {
    final state = await _state(
      oldestSequence: 0,
      newestSequence: 60,
      thumbnailSequences: const [0, 15, 30, 45, 60],
    );

    double secondsBack(int sequence) => _secondsBack(state, sequence);

    final painter = RewindFilmstripPainter(
      state: state,
      secondsBack: secondsBack,
      labelStyle: _labelStyle,
    );

    expect(
      painter.shouldRepaint(
        RewindFilmstripPainter(
          state: state,
          secondsBack: secondsBack,
          labelStyle: _labelStyle,
        ),
      ),
      isFalse,
    );

    expect(
      painter.shouldRepaint(
        RewindFilmstripPainter(
          state: state.copyWith(cursorSequence: 30),
          secondsBack: secondsBack,
          labelStyle: _labelStyle,
        ),
      ),
      isTrue,
    );
  });
}
