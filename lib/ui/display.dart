import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:nes/nes/ppu/frame_buffer.dart';

class DisplayWidget extends StatelessWidget {
  const DisplayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadImage(),
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

  Future<ui.Image> _loadImage() async {
    final frameBuffer = FrameBuffer(width: 256, height: 224)
      ..setPixel(0, 0, 0xFFFFFFFF)
      ..setPixel(1, 0, 0xFFFFFFFF)
      ..setPixel(2, 0, 0xFFFFFFFF)
      ..setPixel(1, 1, 0xFFFFFFFF)
      ..setPixel(1, 2, 0xFFFFFFFF)
      ..setPixel(1, 3, 0xFFFFFFFF)
      ..setPixel(1, 4, 0xFFFFFFFF)
      ..setPixel(4, 0, 0xFFFFFFFF)
      ..setPixel(5, 0, 0xFFFFFFFF)
      ..setPixel(6, 0, 0xFFFFFFFF)
      ..setPixel(4, 1, 0xFFFFFFFF)
      ..setPixel(4, 2, 0xFFFFFFFF)
      ..setPixel(5, 2, 0xFFFFFFFF)
      ..setPixel(6, 2, 0xFFFFFFFF)
      ..setPixel(4, 3, 0xFFFFFFFF)
      ..setPixel(4, 4, 0xFFFFFFFF)
      ..setPixel(5, 4, 0xFFFFFFFF)
      ..setPixel(6, 4, 0xFFFFFFFF)
      ..setPixel(8, 0, 0xFFFFFFFF)
      ..setPixel(9, 0, 0xFFFFFFFF)
      ..setPixel(10, 0, 0xFFFFFFFF)
      ..setPixel(8, 1, 0xFFFFFFFF)
      ..setPixel(8, 2, 0xFFFFFFFF)
      ..setPixel(9, 2, 0xFFFFFFFF)
      ..setPixel(10, 2, 0xFFFFFFFF)
      ..setPixel(10, 3, 0xFFFFFFFF)
      ..setPixel(8, 4, 0xFFFFFFFF)
      ..setPixel(9, 4, 0xFFFFFFFF)
      ..setPixel(10, 4, 0xFFFFFFFF)
      ..setPixel(12, 0, 0xFFFFFFFF)
      ..setPixel(13, 0, 0xFFFFFFFF)
      ..setPixel(14, 0, 0xFFFFFFFF)
      ..setPixel(13, 1, 0xFFFFFFFF)
      ..setPixel(13, 2, 0xFFFFFFFF)
      ..setPixel(13, 3, 0xFFFFFFFF)
      ..setPixel(13, 4, 0xFFFFFFFF);

    final buffer = await ui.ImmutableBuffer.fromUint8List(frameBuffer.pixels);

    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: 256,
      height: 224,
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

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final center = Offset(size.width / 2, size.height / 2);

    final scale = max(1, min(size.width ~/ 256, size.height ~/ 224));

    final width = image.width;
    final height = image.height;

    final topLeft = center - Offset(width / 2, height / 2) * scale.toDouble();

    final matrix = Matrix4.identity().scaled(scale.toDouble())
      ..setTranslationRaw(topLeft.dx, topLeft.dy, 0);

    final paint = Paint()
      ..shader = ImageShader(
        image,
        TileMode.decal,
        TileMode.decal,
        matrix.storage,
      );

    const offset = Offset(1, 1);
    canvas
      ..drawRect(
        topLeft & Size(width * scale.toDouble(), height * scale.toDouble()),
        paint,
      )
      ..drawRect(
        (topLeft - offset) &
            Size(
              (width + 2) * scale.toDouble(),
              (height + 2) * scale.toDouble(),
            ),
        borderPaint,
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
