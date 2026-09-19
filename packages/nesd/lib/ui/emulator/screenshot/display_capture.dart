import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'display_capture.g.dart';

final displayCaptureKey = GlobalKey(debugLabel: 'display-capture');

@riverpod
DisplayCapture displayCapture(Ref ref) => const DisplayCapture();

class DisplayCapture {
  const DisplayCapture();

  Future<ui.Image?> capture() async {
    final context = displayCaptureKey.currentContext;

    if (context == null) {
      return null;
    }

    final boundary = context.findRenderObject();

    if (boundary is! RenderRepaintBoundary) {
      return null;
    }

    if (boundary.debugNeedsPaint) {
      await WidgetsBinding.instance.endOfFrame;
    }

    if (!context.mounted) {
      return null;
    }

    final pixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;

    return await boundary.toImage(pixelRatio: pixelRatio);
  }
}
