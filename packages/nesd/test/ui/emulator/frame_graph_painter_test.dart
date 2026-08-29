import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/ui/emulator/frame_graph_history.dart';
import 'package:nesd/ui/emulator/frame_graph_painter.dart';
import 'package:nesd/ui/theme/base.dart';

class _MockCanvas extends Mock implements Canvas {}

const _height = 100.0;

const _size = Size(4, _height);

const _targetFrameMicroseconds = 16667;

List<Object?> _paint(FrameGraphHistory history) {
  final canvas = _MockCanvas();

  FrameGraphPainter(history: history).paint(canvas, _size);

  return verify(() => canvas.drawRect(captureAny(), captureAny())).captured;
}

void main() {
  setUpAll(() {
    registerFallbackValue(Rect.zero);
    registerFallbackValue(Offset.zero);
    registerFallbackValue(Paint());
  });

  test('draws the newest frame against the right edge', () {
    final history = FrameGraphHistory(capacity: 4)
      ..add(
        frameTimeMicroseconds: _targetFrameMicroseconds,
        sleepTimeMicroseconds: 0,
      )
      ..add(
        frameTimeMicroseconds: _targetFrameMicroseconds,
        sleepTimeMicroseconds: 0,
      );

    final rects = _paint(history).whereType<Rect>().toList();

    expect(rects, hasLength(3));
    expect(
      rects[0],
      rectMoreOrLessEquals(const Rect.fromLTWH(0, 0, 4, 100), epsilon: 0.01),
    );
    expect(
      rects[1],
      rectMoreOrLessEquals(const Rect.fromLTWH(2, 50, 1, 50), epsilon: 0.01),
    );
    expect(
      rects[2],
      rectMoreOrLessEquals(const Rect.fromLTWH(3, 50, 1, 50), epsilon: 0.01),
    );
  });

  test('stacks the sleep segment above the work segment', () {
    final history = FrameGraphHistory(capacity: 4)
      ..add(
        frameTimeMicroseconds: _targetFrameMicroseconds,
        sleepTimeMicroseconds: _targetFrameMicroseconds ~/ 2,
      );

    final bars = _paint(history).whereType<Rect>().skip(1).toList();

    expect(bars, hasLength(2));
    expect(
      bars[0],
      rectMoreOrLessEquals(const Rect.fromLTWH(3, 75, 1, 25), epsilon: 0.01),
    );
    expect(
      bars[1],
      rectMoreOrLessEquals(const Rect.fromLTWH(3, 50, 1, 25), epsilon: 0.01),
    );
  });

  test('tints a column that overran its budget red', () {
    final history = FrameGraphHistory(capacity: 4)
      ..add(frameTimeMicroseconds: 50000, sleepTimeMicroseconds: 0);

    final workPaint = _paint(history).whereType<Paint>().elementAt(1);

    expect(workPaint.color, isSameColorAs(nesdRed));
  });

  test('caps a column that runs off the top of the graph', () {
    final history = FrameGraphHistory(capacity: 4)
      ..add(frameTimeMicroseconds: 50000, sleepTimeMicroseconds: 0);

    final captured = _paint(history);

    expect(
      captured.whereType<Rect>().last,
      rectMoreOrLessEquals(const Rect.fromLTWH(3, 0, 1, 1), epsilon: 0.01),
    );
    expect(captured.whereType<Paint>().last.color, isSameColorAs(nesdRed));
  });

  test('leaves a column that fits inside the graph uncapped', () {
    final history = FrameGraphHistory(capacity: 4)
      ..add(
        frameTimeMicroseconds: _targetFrameMicroseconds,
        sleepTimeMicroseconds: 8000,
      );

    expect(_paint(history).whereType<Rect>(), hasLength(3));
  });

  test('tints a column by its work, not by its paced frame time', () {
    final history = FrameGraphHistory(capacity: 4)
      ..add(
        frameTimeMicroseconds: _targetFrameMicroseconds,
        sleepTimeMicroseconds: 8000,
      );

    final workPaint = _paint(history).whereType<Paint>().elementAt(1);

    expect(workPaint.color, isSameColorAs(Colors.green));
  });

  test('marks the target frame time across the graph', () {
    final history = FrameGraphHistory(capacity: 4)
      ..add(
        frameTimeMicroseconds: _targetFrameMicroseconds,
        sleepTimeMicroseconds: 0,
      );

    final canvas = _MockCanvas();

    FrameGraphPainter(history: history).paint(canvas, _size);

    final captured = verify(
      () => canvas.drawLine(captureAny(), captureAny(), captureAny()),
    ).captured;

    expect(captured.whereType<Offset>(), [
      const Offset(0, 50),
      const Offset(4, 50),
    ]);
  });

  test('colors a frame that holds the target rate green', () {
    expect(frameRateColor(60), Colors.green);
  });

  test('colors a frame just under the target rate yellow', () {
    expect(frameRateColor(55), Colors.yellow);
  });

  test('colors a frame well under the target rate orange', () {
    expect(frameRateColor(45), Colors.orange);
  });

  test('colors a frame below half the target rate red', () {
    expect(frameRateColor(25), nesdRed);
  });

  test('stacks the sleep segment on top of the work segment', () {
    final column = FrameGraphColumn(
      workMicroseconds: frameGraphRangeMicroseconds ~/ 4,
      sleepMicroseconds: frameGraphRangeMicroseconds ~/ 4,
      height: _height,
    );

    expect(column.workHeight, closeTo(25, 0.01));
    expect(column.sleepHeight, closeTo(25, 0.01));
    expect(column.clamped, isFalse);
  });

  test('draws a frame that hits the target rate at half the column', () {
    final column = FrameGraphColumn(
      workMicroseconds: frameGraphTargetMicroseconds.round(),
      sleepMicroseconds: 0,
      height: _height,
    );

    expect(column.workHeight, closeTo(50, 0.01));
  });

  test('fills the column and flags work that overruns the range', () {
    final column = FrameGraphColumn(
      workMicroseconds: (frameGraphRangeMicroseconds * 2).round(),
      sleepMicroseconds: 0,
      height: _height,
    );

    expect(column.workHeight, _height);
    expect(column.sleepHeight, 0);
    expect(column.clamped, isTrue);
  });

  test('truncates sleep so the stack never outgrows the column', () {
    final column = FrameGraphColumn(
      workMicroseconds: (frameGraphRangeMicroseconds * 3) ~/ 4,
      sleepMicroseconds: frameGraphRangeMicroseconds ~/ 2,
      height: _height,
    );

    expect(column.workHeight, closeTo(75, 0.01));
    expect(column.sleepHeight, closeTo(25, 0.01));
    expect(column.clamped, isTrue);
  });

  test('draws nothing for a frame with no recorded time', () {
    final column = FrameGraphColumn(
      workMicroseconds: 0,
      sleepMicroseconds: 0,
      height: _height,
    );

    expect(column.workHeight, 0);
    expect(column.sleepHeight, 0);
    expect(column.clamped, isFalse);
  });
}
