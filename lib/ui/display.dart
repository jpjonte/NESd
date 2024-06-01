import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nes/nes/ppu/frame_buffer.dart';
import 'package:nes/ui/nes_controller.dart';

class DisplayWidget extends ConsumerWidget {
  const DisplayWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(nesControllerProvider.notifier);

    return StreamBuilder(
      stream: controller.stream.asyncMap(_convert),
      builder: (context, snapshot) {
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
          painter: EmulatorPainter(image: image),
          child: const SizedBox.expand(),
        );
      },
    );
  }

  Future<ui.Image> _convert(FrameBuffer frameBuffer) async {
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
}

class EmulatorPainter extends CustomPainter {
  EmulatorPainter({required this.image});

  final ui.Image image;

  final Paint backgroundPaint = Paint()..color = Colors.black;

  final Paint borderPaint = Paint()
    ..strokeWidth = 1
    ..color = Colors.white
    ..style = PaintingStyle.stroke;

  final Paint framePaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, backgroundPaint);

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
        framePaint,
      )
      ..drawRect(
        (topLeft - offset) &
            Size(
              (width + 1) * scale.toDouble(),
              (height + 1) * scale.toDouble(),
            ),
        borderPaint,
      );
  }

  @override
  bool shouldRepaint(covariant EmulatorPainter oldDelegate) =>
      image != oldDelegate.image;
}
