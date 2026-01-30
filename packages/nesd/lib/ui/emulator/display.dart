import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/emulator/display_controller.dart';
import 'package:nesd/ui/emulator/emulator_painters.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/settings/graphics/scaling.dart';
import 'package:nesd/ui/settings/settings.dart';

class FrameBufferStreamBuilder extends HookConsumerWidget {
  const FrameBufferStreamBuilder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nes = ref.watch(nesStateProvider);

    if (nes == null) {
      return const SizedBox();
    }

    final controller = ref.watch(displayFrameControllerProvider);

    final frameState = useValueListenable(controller);

    return switch (frameState) {
      TextureDisplayFrameState(:final textureId, :final width, :final height) =>
        DisplayBuilder.texture(
          textureId: textureId,
          imageWidth: width,
          imageHeight: height,
        ),
      ImageDisplayFrameState(:final image) => DisplayBuilder.image(
        image: image,
      ),
      _ => const ColoredBox(color: Colors.black),
    };
  }
}

class DisplayBuilder extends ConsumerWidget {
  const DisplayBuilder._({
    required this.image,
    required this.textureId,
    required this.imageWidth,
    required this.imageHeight,
    super.key,
  });

  factory DisplayBuilder.image({required ui.Image image, Key? key}) {
    return DisplayBuilder._(
      key: key,
      image: image,
      textureId: null,
      imageWidth: image.width,
      imageHeight: image.height,
    );
  }

  factory DisplayBuilder.texture({
    required int textureId,
    required int imageWidth,
    required int imageHeight,
    Key? key,
  }) {
    return DisplayBuilder._(
      key: key,
      image: null,
      textureId: textureId,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
  }

  final ui.Image? image;

  final int imageWidth;
  final int imageHeight;

  final int? textureId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final nes = ref.watch(nesStateProvider);

    final widthScale = settings.stretch ? 8 / 7 : 1.0;

    return LayoutBuilder(
      builder: (_, constraints) {
        final maxScale = min(
          constraints.maxWidth / imageWidth,
          constraints.maxHeight / imageHeight,
        );

        final scale = min(
          maxScale,
          _calculateScale(
            settings,
            constraints.maxWidth,
            constraints.maxHeight,
            imageWidth,
            imageHeight,
          ),
        );

        final narrow = constraints.maxWidth < constraints.maxHeight;

        final screenWidth = imageWidth;
        final screenHeight = (imageHeight / widthScale).round();

        final screenSize = Size(
          screenWidth.toDouble(),
          screenHeight.toDouble(),
        );
        final scaledSize = screenSize * scale;

        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

        final anchorAtTop = settings.showTouchControls && narrow;

        final center = Offset(
          canvasSize.width / 2,
          anchorAtTop ? canvasSize.height / 4 : canvasSize.height / 2,
        );

        final topLeft =
            center - Offset(scaledSize.width / 2, scaledSize.height / 2);

        final baseLayer = textureId != null
            ? SizedBox.expand(
                child: Texture(
                  textureId: textureId!,
                  filterQuality: FilterQuality.none,
                ),
              )
            : CustomPaint(
                painter: CpuFramePainter(image: image!),
                child: const SizedBox.expand(),
              );

        final overlayLayer = CustomPaint(
          painter: EmulatorOverlayPainter(
            scale: scale,
            showBorder: settings.showBorder,
            paused: nes?.paused ?? false,
            fastForward: nes?.fastForward ?? false,
            rewind: nes?.rewind ?? false,
            crossHairPosition:
                nes?.bus.cartridge.databaseEntry?.hasZapper == true
                ? nes?.bus.zapperPosition
                : null,
          ),
          child: const SizedBox.expand(),
        );

        final screen = SizedBox(
          width: scaledSize.width,
          height: scaledSize.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(child: baseLayer),
              overlayLayer,
            ],
          ),
        );

        final child = Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(child: ColoredBox(color: Colors.black)),
            Positioned(
              left: topLeft.dx,
              top: topLeft.dy,
              width: scaledSize.width,
              height: scaledSize.height,
              child: screen,
            ),
          ],
        );

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
                child: child,
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
    int imageWidth,
    int imageHeight,
  ) {
    return switch (settings.scaling) {
      Scaling.x1 => 1.0,
      Scaling.x2 => 2.0,
      Scaling.x3 => 3.0,
      Scaling.x4 => 4.0,
      Scaling.autoInteger => max(
        0.5,
        min(width ~/ imageWidth, height ~/ imageHeight),
      ).toDouble(),
      Scaling.autoSmooth => 1000,
    };
  }
}
