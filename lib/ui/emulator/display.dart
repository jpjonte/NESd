import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/event/nes_event.dart';
import 'package:nesd/nes/ppu/frame_buffer.dart';
import 'package:nesd/ui/emulator/input/keyboard/keyboard_input_handler.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/settings/graphics/scaling.dart';
import 'package:nesd/ui/settings/settings.dart';

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

class FrameBufferStreamBuilder extends HookConsumerWidget {
  const FrameBufferStreamBuilder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyboardInputHandler = ref.watch(keyboardInputHandlerProvider);
    final eventBus = ref.watch(eventBusProvider);
    final nes = ref.watch(nesStateProvider);

    if (nes == null) {
      return const SizedBox();
    }

    useStream(
      eventBus.stream.where(
        (event) =>
            event is FrameNesEvent ||
            event is SuspendNesEvent ||
            event is DebuggerNesEvent,
      ),
    );

    return Focus(
      autofocus: true,
      onKeyEvent:
          (focusNode, event) =>
              keyboardInputHandler.handleKeyEvent(event)
                  ? KeyEventResult.handled
                  : KeyEventResult.ignored,
      child: DisplayWidget(
        paused: nes.paused,
        fastForward: nes.fastForward,
        imageFuture: convertFrameBufferToImage(nes.ppu.frameBuffer),
      ),
    );
  }
}

class DisplayWidget extends HookConsumerWidget {
  static const menuKey = Key('menu');

  const DisplayWidget({
    required this.imageFuture,
    this.paused = false,
    this.fastForward = false,
    super.key,
  });

  final Future<ui.Image> imageFuture;

  final bool paused;
  final bool fastForward;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = useFuture(imageFuture);

    final theme = Theme.of(context);

    return Stack(
      children: [
        switch (snapshot) {
          AsyncSnapshot<ui.Image>(data: final image?) => DisplayBuilder(
            image: image,
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Theme(
              data: theme.copyWith(
                iconButtonTheme: IconButtonThemeData(
                  style: theme.iconButtonTheme.style!.copyWith(
                    backgroundColor: WidgetStateProperty.all(
                      Colors.black.withAlpha(150),
                    ),
                  ),
                ),
              ),
              child: IconButton(
                key: menuKey,
                icon: const Icon(Icons.menu),
                color: Colors.white,
                onPressed:
                    () => ref.read(routerProvider).navigate(const MenuRoute()),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DisplayBuilder extends ConsumerWidget {
  const DisplayBuilder({required this.image, super.key});

  final ui.Image image;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final nes = ref.watch(nesStateProvider);

    final widthScale = settings.stretch ? 8 / 7 : 1.0;

    return LayoutBuilder(
      builder: (_, constraints) {
        final maxScale = min(
          constraints.maxWidth / image.width,
          constraints.maxHeight / image.height,
        );

        final scale = min(
          maxScale,
          _calculateScale(
            settings,
            constraints.maxWidth,
            constraints.maxHeight,
            image,
          ),
        );

        final narrow = constraints.maxWidth < constraints.maxHeight;

        final width = image.width;
        final height = (image.height / widthScale).round();

        final screenSize = Size(width.toDouble(), height.toDouble());
        final scaledSize = screenSize * scale;

        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

        final anchorAtTop = settings.showTouchControls && narrow;

        final center = Offset(
          canvasSize.width / 2,
          anchorAtTop ? canvasSize.height / 4 : canvasSize.height / 2,
        );

        final topLeft =
            center - Offset(scaledSize.width / 2, scaledSize.height / 2);

        return ConstrainedBox(
          constraints: constraints,
          child: ClipRect(
            child: MouseRegion(
              onHover: (event) {
                final displayPosition = event.localPosition - topLeft;
                final nesPosition = displayPosition / scale;

                if (!screenSize.contains(nesPosition)) {
                  nes?.bus.zapperPosition = null;
                } else {
                  nes?.bus.zapperPosition = nesPosition;
                }
              },
              child: GestureDetector(
                onTapDown: (details) {
                  final displayPosition = details.localPosition - topLeft;
                  final nesPosition = displayPosition / scale;

                  if (!screenSize.contains(nesPosition)) {
                    return;
                  }

                  nes?.bus.zapperPosition = nesPosition;
                  nes?.bus.zapperPull();
                },
                onTapUp: (details) {
                  final displayPosition = details.localPosition - topLeft;
                  final nesPosition = displayPosition / scale;

                  if (screenSize.contains(nesPosition)) {
                    nes?.bus.zapperPosition = nesPosition;
                  }

                  nes?.bus.zapperRelease();
                },
                child: CustomPaint(
                  painter: EmulatorPainter(
                    center: center,
                    topLeft: topLeft,
                    screenSize: scaledSize,
                    scale: scale,
                    image: image,
                    paused: nes?.paused ?? false,
                    fastForward: nes?.fastForward ?? false,
                    rewind: nes?.rewind ?? false,
                    showBorder: settings.showBorder,
                    crossHairPosition:
                        nes?.bus.cartridge.databaseEntry?.hasZapper == true
                            ? nes?.bus.zapperPosition
                            : null,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _calculateScale(
    Settings settings,
    double width,
    double height,
    ui.Image image,
  ) {
    return switch (settings.scaling) {
      Scaling.x1 => 1.0,
      Scaling.x2 => 2.0,
      Scaling.x3 => 3.0,
      Scaling.x4 => 4.0,
      Scaling.autoInteger =>
        max(0.5, min(width ~/ image.width, height ~/ image.height)).toDouble(),
      Scaling.autoSmooth => 1000,
    };
  }
}

class EmulatorPainter extends CustomPainter {
  EmulatorPainter({
    required this.image,
    required this.center,
    required this.topLeft,
    required this.screenSize,
    required this.scale,
    required this.showBorder,
    required this.paused,
    required this.fastForward,
    required this.rewind,
    this.crossHairPosition,
  });

  final ui.Image image;

  final Offset center;
  final Offset topLeft;
  final Size screenSize;
  final double scale;

  final bool showBorder;
  final bool paused;
  final bool fastForward;
  final bool rewind;

  final Offset? crossHairPosition;

  final _backgroundPaint = Paint()..color = Colors.black;

  final _pauseOverlayPaint =
      Paint()..color = Colors.black.withValues(alpha: 0.5);

  final _iconPaint = Paint()..color = Colors.white;

  final _outlinePaint =
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;

  final _borderPaint =
      Paint()
        ..strokeWidth = 1
        ..color = Colors.white
        ..style = PaintingStyle.stroke;

  final _crossHairPaint =
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..blendMode = BlendMode.difference
        ..strokeWidth = 4;

  final _framePaint = Paint();

  final _fastForwardPath =
      Path()
        ..addPolygon([
          const Offset(0, -16),
          const Offset(16, 0),
          const Offset(0, 16),
        ], true)
        ..addPolygon([
          const Offset(14, -16),
          const Offset(30, 0),
          const Offset(14, 16),
        ], true);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, _backgroundPaint);

    _drawScreen(canvas, topLeft, screenSize);

    if (showBorder) {
      _drawBorder(canvas, topLeft, screenSize);
    }

    if (paused) {
      _drawPause(canvas, size, center);
    } else if (crossHairPosition case final crossHairPosition?) {
      _drawCrossHair(canvas, topLeft + crossHairPosition * scale);
    }

    if (fastForward) {
      _drawFastForward(canvas, size, topLeft + const Offset(8, 24));
    }

    if (rewind) {
      _drawFastForward(
        canvas,
        size,
        topLeft + const Offset(32, 24),
        mirror: true,
      );
    }
  }

  void _drawScreen(Canvas canvas, Offset topLeft, Size screenSize) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      topLeft & screenSize,
      _framePaint,
    );
  }

  void _drawBorder(Canvas canvas, Offset topLeft, Size screenSize) {
    const offset = Offset(1, 1);

    canvas.drawRect((topLeft - offset) & screenSize + offset, _borderPaint);
  }

  void _drawPause(Canvas canvas, Size size, Offset center) {
    canvas
      ..drawRect(Offset.zero & size, _pauseOverlayPaint)
      ..drawRect(center.translate(-16, -16) & const Size(16, 48), _outlinePaint)
      ..drawRect(center.translate(-16, -16) & const Size(16, 48), _iconPaint)
      ..drawRect(center.translate(16, -16) & const Size(16, 48), _outlinePaint)
      ..drawRect(center.translate(16, -16) & const Size(16, 48), _iconPaint);
  }

  void _drawFastForward(
    Canvas canvas,
    Size size,
    Offset center, {
    bool mirror = false,
  }) {
    final path = _fastForwardPath
        .transform(Matrix4.diagonal3Values(mirror ? -1 : 1, 1, 1).storage)
        .shift(center);

    canvas
      ..drawPath(path, _outlinePaint)
      ..drawPath(path, _iconPaint);
  }

  void _drawCrossHair(Canvas canvas, Offset crossHairPosition) {
    final size = 6.0 * scale;

    canvas
      ..drawLine(
        crossHairPosition - Offset(size, 0),
        crossHairPosition + Offset(size, 0),
        _crossHairPaint,
      )
      ..drawLine(
        crossHairPosition - Offset(0, size),
        crossHairPosition + Offset(0, size),
        _crossHairPaint,
      );
  }

  @override
  bool shouldRepaint(covariant EmulatorPainter oldDelegate) =>
      image != oldDelegate.image;
}
