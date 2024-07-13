import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/nes/ppu/frame_buffer.dart';
import 'package:nesd/nes/ppu/ppu.dart';
import 'package:nesd/ui/emulator/display.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';

class TileDebugWidget extends HookConsumerWidget {
  const TileDebugWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nes = ref.read(nesStateProvider);
    final controller = ref.read(nesControllerProvider);

    final stream = useStream(controller.frameBufferStream);

    if (nes == null) {
      return const SizedBox();
    }

    if (stream.hasError) {
      return Center(
        child: Text(
          'Error: ${stream.error}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (!stream.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<ui.Image>(
      future: _buildTileImage(nes),
      builder: (context, snapshot) {
        final image = snapshot.data;

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (image == null || !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return SizedBox(
          width: image.width.toDouble(),
          height: image.height.toDouble(),
          child: ClipRect(
            child: CustomPaint(
              painter: TileDebugPainter(
                image: image,
                nes: nes,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<ui.Image> _buildTileImage(NES nes) async {
    const nametableWidth = 32 * 8;
    const nametableHeight = 30 * 8;

    const width = 2 * nametableWidth;
    const height = 2 * nametableHeight;

    final buffer = FrameBuffer(width: width, height: height);

    final patternTableIndex = nes.ppu.PPUCTRL_B;

    for (var n = 0; n < 4; n++) {
      final nx = n % 2;
      final ny = n ~/ 2;

      for (var ty = 0; ty < 30; ty++) {
        for (var tx = 0; tx < 32; tx++) {
          final nametableByte =
              nes.bus.ppuRead(0x2000 | n << 10 | ty << 5 | tx);
          final attributeByte = nes.bus
              .ppuRead(0x23c0 | n << 10 | (ty & 0x1c) << 1 | (tx & 0x1c) >> 2);
          final quadrantShift = (ty & 0x02) << 1 | tx & 0x02;
          final attribute = (attributeByte >> quadrantShift) & 0x03;

          for (var py = 0; py < 8; py++) {
            final patternTableLowByte = nes.bus
                .ppuRead(patternTableIndex << 12 | nametableByte << 4 | py);
            final patternTableHighByte = nes.bus
                .ppuRead(patternTableIndex << 12 | nametableByte << 4 | py + 8);

            for (var px = 0; px < 8; px++) {
              final patternHigh = (patternTableHighByte >> (7 - px)) & 0x1;
              final patternLow = (patternTableLowByte >> (7 - px)) & 0x1;

              final pattern = (patternHigh << 1) | patternLow;

              final paletteIndex = attribute << 2 | pattern;

              final index = pattern > 0 ? paletteIndex : 0x10;

              final systemPaletteIndex = nes.bus.ppuRead(0x3f00 | index);

              final color = systemPalette[systemPaletteIndex];

              buffer.setPixel(
                nx * nametableWidth + tx * 8 + px,
                ny * nametableHeight + ty * 8 + py,
                color,
              );
            }
          }
        }
      }
    }

    return convertFrameBufferToImage(buffer);
  }
}

class TileDebugPainter extends CustomPainter {
  TileDebugPainter({required this.image, required this.nes});

  final ui.Image image;
  final NES nes;

  final Paint backgroundPaint = Paint()..color = Colors.black;

  final Paint borderPaint = Paint()
    ..strokeWidth = 1
    ..color = Colors.white
    ..style = PaintingStyle.stroke;

  final _imagePaint = Paint();
  final _scrollStrokePaint = Paint()
    ..color = const Color(0xffff00ff)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final _scrollFillPaint = Paint()
    ..color = const Color(0x33ff00ff)
    ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final scrollX =
        (nes.ppu.PPUCTRL_X << 8 | nes.ppu.t_coarseX << 3 | nes.ppu.x)
            .toDouble();
    final scrollY =
        (nes.ppu.PPUCTRL_Y << 8 | nes.ppu.t_coarseY << 3 | nes.ppu.t_fineY)
            .toDouble();

    const visibleArea = Size(32 * 8, 30 * 8);

    canvas
      ..drawRect(Offset.zero & size, backgroundPaint)
      ..drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
        _imagePaint,
      )
      ..drawRect(
        Offset(scrollX, scrollY) & visibleArea,
        _scrollStrokePaint,
      )
      ..drawRect(
        Offset(scrollX, scrollY) & visibleArea,
        _scrollFillPaint,
      );

    if (scrollX > 32 * 8) {
      canvas
        ..drawRect(
          Offset(scrollX - 64 * 8, scrollY) & visibleArea,
          _scrollStrokePaint,
        )
        ..drawRect(
          Offset(scrollX - 64 * 8, scrollY) & visibleArea,
          _scrollFillPaint,
        );
    }

    if (scrollY > 30 * 8) {
      canvas
        ..drawRect(
          Offset(scrollX, scrollY - 60 * 8) & visibleArea,
          _scrollStrokePaint,
        )
        ..drawRect(
          Offset(scrollX, scrollY - 60 * 8) & visibleArea,
          _scrollFillPaint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant TileDebugPainter oldDelegate) =>
      image != oldDelegate.image;
}
