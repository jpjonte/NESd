import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:nesd/ui/emulator/rewind/rewind_scrub_controller.dart';

const rewindFilmstripRulerHeight = 24.0;

const _cellAspectRatio = 256 / 240;

double rewindFilmstripCellWidth(double filmHeight) =>
    filmHeight * _cellAspectRatio;

int rewindFilmstripSlotStride(RewindScrubState state) {
  final sequences = state.thumbnailSequences;

  if (sequences.length >= 2) {
    return max(1, sequences[1] - sequences[0]);
  }

  return max(1, state.frameRate ~/ state.captureInterval);
}

const _backgroundColor = Colors.black54;
const _placeholderColor = Colors.white10;
const _cellBorderColor = Colors.white24;
const _cursorColor = Colors.white;

const _settlingCursorColor = Colors.orange;

const _trackColor = Colors.white24;
const _trackFillColor = Colors.white70;

const _cellGap = 4.0;
const _cursorWidth = 2.0;
const _cursorKnobRadius = 4.0;
const _trackHeight = 3.0;

class RewindFilmstripPainter extends CustomPainter {
  RewindFilmstripPainter({
    required this.state,
    required this.secondsBack,
    required this.labelStyle,
  });

  final RewindScrubState state;

  final double Function(int sequence) secondsBack;

  final TextStyle labelStyle;

  late final Paint _backgroundPaint = Paint()..color = _backgroundColor;

  late final Paint _placeholderPaint = Paint()..color = _placeholderColor;

  late final Paint _borderPaint = Paint()
    ..color = _cellBorderColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  late final Paint _imagePaint = Paint()..filterQuality = FilterQuality.low;

  late final Paint _cursorPaint = Paint()
    ..color = state.settled ? _cursorColor : _settlingCursorColor;

  late final Paint _trackPaint = Paint()..color = _trackColor;

  late final Paint _trackFillPaint = Paint()..color = _trackFillColor;

  late final Map<int, int> _indexBySequence = {
    for (var i = 0; i < state.thumbnailSequences.length; i++)
      state.thumbnailSequences[i]: i,
  };

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, _backgroundPaint);

    final filmHeight = size.height - rewindFilmstripRulerHeight;

    if (filmHeight <= 0 || size.width <= 0) {
      return;
    }

    final cellWidth = rewindFilmstripCellWidth(filmHeight);
    final anchor = _anchorSequence;
    final stride = _slotStride;

    final anchorX =
        size.width / 2 + (anchor - state.cursorSequence) * cellWidth / stride;

    final firstSlot = ((-cellWidth / 2 - anchorX) / cellWidth).ceil();
    final lastSlot = ((size.width + cellWidth / 2 - anchorX) / cellWidth)
        .floor();

    for (var slot = firstSlot; slot <= lastSlot; slot++) {
      final sequence = anchor + slot * stride;

      if (sequence < state.oldestSequence || sequence > state.newestSequence) {
        continue;
      }

      final centerX = anchorX + slot * cellWidth;

      _paintCell(canvas, _cellRect(centerX, cellWidth, filmHeight), sequence);
      _paintTick(canvas, centerX, filmHeight, sequence);
    }

    _paintCursor(canvas, size, filmHeight);
    _paintTrack(canvas, size);
  }

  Rect _cellRect(double centerX, double cellWidth, double filmHeight) =>
      Rect.fromLTWH(
        centerX - cellWidth / 2 + _cellGap / 2,
        _cellGap / 2,
        cellWidth - _cellGap,
        filmHeight - _cellGap,
      );

  void _paintCell(Canvas canvas, Rect rect, int sequence) {
    final image = _thumbnailFor(sequence);

    if (image == null) {
      canvas
        ..drawRect(rect, _placeholderPaint)
        ..drawRect(rect, _borderPaint);

      return;
    }

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      rect,
      _imagePaint,
    );
  }

  void _paintTick(
    Canvas canvas,
    double centerX,
    double filmHeight,
    int sequence,
  ) {
    final label = _label(tickLabel(sequence));

    label.paint(
      canvas,
      Offset(
        centerX - label.width / 2,
        filmHeight + (rewindFilmstripRulerHeight - label.height) / 2,
      ),
    );
  }

  @visibleForTesting
  String tickLabel(int sequence) {
    final seconds = secondsBack(sequence);
    final spacing = _slotStride * state.captureInterval / state.frameRate;
    final wholeSeconds = (spacing - spacing.roundToDouble()).abs() < 1e-6;

    return '-${seconds.toStringAsFixed(wholeSeconds ? 0 : 1)}s';
  }

  TextPainter _label(String text) => TextPainter(
    text: TextSpan(text: text, style: labelStyle),
    textDirection: TextDirection.ltr,
  )..layout();

  void _paintCursor(Canvas canvas, Size size, double filmHeight) {
    final centerX = size.width / 2;

    canvas
      ..drawRect(
        Rect.fromLTWH(centerX - _cursorWidth / 2, 0, _cursorWidth, filmHeight),
        _cursorPaint,
      )
      ..drawCircle(
        Offset(centerX, _cursorKnobRadius),
        _cursorKnobRadius,
        _cursorPaint,
      );
  }

  void _paintTrack(Canvas canvas, Size size) {
    final top = size.height - _trackHeight;

    canvas
      ..drawRect(Rect.fromLTWH(0, top, size.width, _trackHeight), _trackPaint)
      ..drawRect(
        Rect.fromLTWH(0, top, size.width * _cursorFraction, _trackHeight),
        _trackFillPaint,
      );
  }

  double get _cursorFraction {
    final span = state.newestSequence - state.oldestSequence;

    if (span <= 0) {
      return 1;
    }

    return ((state.cursorSequence - state.oldestSequence) / span).clamp(
      0.0,
      1.0,
    );
  }

  ui.Image? _thumbnailFor(int sequence) {
    final index = _indexBySequence[sequence];

    if (index == null || index >= state.thumbnails.length) {
      return null;
    }

    return state.thumbnails[index];
  }

  int get _anchorSequence => state.thumbnailSequences.isEmpty
      ? state.cursorSequence
      : state.thumbnailSequences.first;

  int get _slotStride => rewindFilmstripSlotStride(state);

  @override
  bool shouldRepaint(RewindFilmstripPainter oldDelegate) =>
      oldDelegate.state != state;
}
