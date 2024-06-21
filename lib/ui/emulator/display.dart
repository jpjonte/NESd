import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nes/nes/ppu/frame_buffer.dart';
import 'package:nes/ui/emulator/nes_controller.dart';
import 'package:nes/ui/settings/settings.dart';

Future<ui.Image> convertFrameBufferToImage(FrameBuffer frameBuffer) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(frameBuffer.pixels);

  final descriptor = ui.ImageDescriptor.raw(
    buffer,
    width: frameBuffer.width,
    height: frameBuffer.height,
    pixelFormat: ui.PixelFormat.rgba8888,
  );

  final codec = await descriptor.instantiateCodec();

  final frame = await codec.getNextFrame();

  return frame.image;
}

class DisplayWidget extends ConsumerWidget {
  const DisplayWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.watch(nesControllerProvider.notifier);
    final nes = ref.watch(nesControllerProvider);

    final mediaQuery = MediaQuery.of(context);

    return StreamBuilder(
      stream: controller.frameBufferStream.asyncMap(convertFrameBufferToImage),
      builder: (context, snapshot) {
        if (!nes.on) {
          return const SizedBox();
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final image = snapshot.data;

        if (image == null) {
          return const Center(child: Text('Failed to load image'));
        }

        final scale = switch (settings.scaling) {
          Scaling.x1 => 1.0,
          Scaling.x2 => 2.0,
          Scaling.x3 => 3.0,
          Scaling.x4 => 4.0,
          Scaling.autoInteger => max(
              1,
              min(
                mediaQuery.size.width ~/ image.width,
                mediaQuery.size.height ~/ image.height,
              ),
            ),
          Scaling.autoSmooth => max(
              0.5,
              min(
                mediaQuery.size.width / image.width,
                mediaQuery.size.height / image.height,
              ),
            ),
        };

        final widthScale = settings.stretch ? 8 / 7 : 1.0;

        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: mediaQuery.size.width,
            maxHeight: mediaQuery.size.height,
          ),
          child: ClipRect(
            child: CustomPaint(
              painter: EmulatorPainter(
                image: image,
                paused: !nes.running,
                scale: scale.toDouble(),
                widthScale: widthScale,
                showBorder: settings.showBorder,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }
}

class EmulatorPainter extends CustomPainter {
  EmulatorPainter({
    required this.image,
    required this.scale,
    required this.widthScale,
    required this.showBorder,
    required this.paused,
  });

  final ui.Image image;

  final double scale;
  final double widthScale;
  final bool showBorder;
  final bool paused;

  final _backgroundPaint = Paint()..color = Colors.black;

  final _pauseOverlayPaint = Paint()..color = Colors.black.withOpacity(0.5);

  final _pauseIconPaint = Paint()..color = Colors.white;

  final _borderPaint = Paint()
    ..strokeWidth = 1
    ..color = Colors.white
    ..style = PaintingStyle.stroke;

  final _framePaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, _backgroundPaint);

    final center = Offset(size.width / 2, size.height / 2);

    final width = (image.width * widthScale).round();
    final height = image.height;

    final topLeft = center - Offset(width / 2, height / 2) * scale;

    const offset = Offset(1, 1);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      topLeft & Size(width * scale, height * scale),
      _framePaint,
    );

    if (showBorder) {
      canvas.drawRect(
        (topLeft - offset) &
            Size(
              (width + 1) * scale,
              (height + 1) * scale,
            ),
        _borderPaint,
      );
    }

    if (paused) {
      canvas
        ..drawRect(Offset.zero & size, _pauseOverlayPaint)
        ..drawRect(
          center.translate(-16, -16) & const Size(16, 48),
          _pauseIconPaint,
        )
        ..drawRect(
          center.translate(16, -16) & const Size(16, 48),
          _pauseIconPaint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant EmulatorPainter oldDelegate) =>
      image != oldDelegate.image;
}
