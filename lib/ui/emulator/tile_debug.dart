import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/extension/hex_extension.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/nes/ppu/frame_buffer.dart';
import 'package:nesd/nes/ppu/ppu.dart';
import 'package:nesd/ui/emulator/cartridge_info.dart';
import 'package:nesd/ui/emulator/display.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';

int getNametableAddress(int n, int ty, int tx) =>
    0x2000 | n << 10 | ty << 5 | tx;

int getPalette(int attributeByte, int n, int ty, int tx) {
  final quadrantShift = (ty & 0x02) << 1 | tx & 0x02;
  final attribute = (attributeByte >> quadrantShift) & 0x03;

  return attribute;
}

int getAttributeAddress(int n, int ty, int tx) =>
    0x23c0 | n << 10 | (ty & 0x1c) << 1 | (tx & 0x1c) >> 2;

int getChrAddress(int patternTableIndex, int nametableByte) {
  return patternTableIndex << 12 | nametableByte << 4;
}

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

        return TileDebugContent(image: image, nes: nes);
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
          final nametableByte = nes.bus.ppuRead(getNametableAddress(n, ty, tx));
          final attributeByte = nes.bus.ppuRead(getAttributeAddress(n, ty, tx));
          final palette = getPalette(attributeByte, n, ty, tx);

          final chrAddress = getChrAddress(patternTableIndex, nametableByte);

          for (var py = 0; py < 8; py++) {
            final patternTableLowByte = nes.bus.ppuRead(chrAddress + py);
            final patternTableHighByte = nes.bus
                .ppuRead(patternTableIndex << 12 | nametableByte << 4 | py + 8);

            for (var px = 0; px < 8; px++) {
              final patternHigh = (patternTableHighByte >> (7 - px)) & 0x1;
              final patternLow = (patternTableLowByte >> (7 - px)) & 0x1;

              final pattern = (patternHigh << 1) | patternLow;

              final paletteIndex = palette << 2 | pattern;

              final index = pattern > 0 ? paletteIndex : 0x10;

              final paletteAddress = 0x3f00 | index;

              final systemPaletteIndex = nes.bus.ppuRead(paletteAddress);

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

class TileDebugContent extends HookWidget {
  const TileDebugContent({
    required this.image,
    required this.nes,
    super.key,
  });

  final ui.Image image;
  final NES nes;

  @override
  Widget build(BuildContext context) {
    final locked = useState(false);
    final active = useState(false);

    final mousePosition = useState(Offset.zero);
    final position = useState(Offset.zero);

    final xOverflow = position.value.dx + 210 > image.width;
    final yOverflow = position.value.dy + 240 > image.height;

    const padding = 8;

    final left = xOverflow ? null : position.value.dx + padding;
    final top = yOverflow ? null : position.value.dy + padding;
    final right = xOverflow ? image.width - position.value.dx + padding : null;
    final bottom =
        yOverflow ? image.height - position.value.dy + padding : null;

    final show = active.value || locked.value;

    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            locked.value = !locked.value;

            if (!locked.value) {
              position.value = mousePosition.value;
            }
          },
          child: MouseRegion(
            onEnter: (e) {
              mousePosition.value = e.localPosition;

              active.value = true;

              if (!locked.value) {
                position.value = mousePosition.value;
              }
            },
            onHover: (e) {
              mousePosition.value = e.localPosition;

              if (!locked.value) {
                position.value = mousePosition.value;
              }
            },
            onExit: (e) {
              mousePosition.value = Offset.zero;

              active.value = false;

              if (!locked.value) {
                position.value = Offset.zero;
              }
            },
            child: SizedBox(
              width: image.width.toDouble(),
              height: image.height.toDouble(),
              child: ClipRect(
                child: CustomPaint(
                  painter: TileDebugPainter(
                    image: image,
                    nes: nes,
                    highlight: show ? position.value : null,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (show)
          Positioned(
            left: left,
            top: top,
            right: right,
            bottom: bottom,
            child: TileTooltip(
              nes: nes,
              position: position.value,
              locked: locked.value,
            ),
          ),
      ],
    );
  }
}

class TileTooltip extends StatelessWidget {
  const TileTooltip({
    required this.nes,
    required this.position,
    required this.locked,
    super.key,
  });

  final NES nes;
  final Offset position;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final x = position.dx.round();
    final y = position.dy.round();

    final nx = x ~/ 256;
    final ny = y ~/ 240;
    final n = 2 * ny + nx;

    final tx = (x ~/ 8) % 32;
    final ty = (y ~/ 8) % 30;

    final address = 0x2000 + 0x400 * n + 32 * ty + tx;

    final nametableByte = nes.bus.ppuRead(getNametableAddress(n, ty, tx));
    final attributeAddress = getAttributeAddress(n, ty, tx);
    final attribute = nes.bus.ppuRead(attributeAddress);
    final palette = getPalette(attribute, n, ty, tx);

    final patternTableIndex = nes.ppu.PPUCTRL_B;

    final chrAddress = getChrAddress(patternTableIndex, nametableByte);

    final paletteAddress = 0x3f00 | palette << 2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      width: 200,
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(200),
        border: Border.all(color: Colors.white),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: 'Ubuntu Mono',
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KeyValue('Address', address.toHex(width: 4, prefix: true)),
            KeyValue('Nametable', '$n'),
            KeyValue('Coordinates', '${tx * 8}, ${ty * 8}'),
            KeyValue('Tile coords', '$tx, $ty'),
            KeyValue('Tile index', nametableByte.toHex(prefix: true)),
            KeyValue('Attribute address', attributeAddress.toHex(prefix: true)),
            KeyValue('Attribute', attribute.toHex(prefix: true)),
            KeyValue('Palette', '$palette'),
            KeyValue(
              'Palette address',
              paletteAddress.toHex(width: 4, prefix: true),
            ),
            KeyValue('CHR address', chrAddress.toHex(width: 4, prefix: true)),
          ],
        ),
      ),
    );
  }
}

class TileDebugPainter extends CustomPainter {
  TileDebugPainter({
    required this.image,
    required this.nes,
    required this.highlight,
  });

  final ui.Image image;
  final NES nes;
  final Offset? highlight;

  final Paint backgroundPaint = Paint()..color = Colors.black;

  final _highlightFillPaint = Paint()
    ..color = Colors.black.withAlpha(50)
    ..style = PaintingStyle.fill;
  final _highlightBorderPaint = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  final _imagePaint = Paint();
  final _scrollStrokePaint = Paint()
    ..color = const Color(0xccff00ff)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final _scrollFillPaint = Paint()
    ..color = const Color(0x30ff00ff)
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

    if (highlight != null) {
      final x = highlight!.dx ~/ 8;
      final y = highlight!.dy ~/ 8;

      final rect = Rect.fromLTWH(x * 8, y * 8, 8, 8);

      canvas
        ..drawRect(rect, _highlightFillPaint)
        ..drawRect(rect, _highlightBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant TileDebugPainter oldDelegate) =>
      image != oldDelegate.image;
}
