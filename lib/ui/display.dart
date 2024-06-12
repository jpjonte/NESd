import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nes/nes/nes.dart';
import 'package:nes/nes/ppu/frame_buffer.dart';
import 'package:nes/ui/nes_controller.dart';

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
    final controller = ref.watch(nesControllerProvider.notifier);
    final nes = ref.watch(nesControllerProvider);

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

        return CustomPaint(
          painter: EmulatorPainter(image: image, nes: nes),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class EmulatorPainter extends CustomPainter {
  EmulatorPainter({required this.image, required this.nes});

  final ui.Image image;
  final NES nes;

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

    const widthScale = 8 / 7;

    final width = (image.width * widthScale).round();
    final height = image.height;

    final scale = max(
      1,
      min(size.width ~/ width, size.height ~/ height),
    );

    final topLeft = center - Offset(width / 2, height / 2) * scale.toDouble();

    const offset = Offset(1, 1);
    canvas
      ..drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        topLeft & Size(width * scale.toDouble(), height * scale.toDouble()),
        _framePaint,
      )
      ..drawRect(
        (topLeft - offset) &
            Size(
              (width + 1) * scale.toDouble(),
              (height + 1) * scale.toDouble(),
            ),
        _borderPaint,
      );

    if (!nes.running) {
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
