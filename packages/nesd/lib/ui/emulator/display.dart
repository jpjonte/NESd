import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/nes/region.dart';
import 'package:nesd/ui/emulator/display_controller.dart';
import 'package:nesd/ui/emulator/display_geometry.dart';
import 'package:nesd/ui/emulator/display_position.dart';
import 'package:nesd/ui/emulator/emulator_painters.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/overscan.dart';
import 'package:nesd/ui/emulator/overscan_crop.dart';
import 'package:nesd/ui/emulator/video_filter/crt_filter_settings.dart';
import 'package:nesd/ui/emulator/video_filter/shader_frame_painter.dart';
import 'package:nesd/ui/emulator/video_filter/video_filter.dart';
import 'package:nesd/ui/emulator/video_filter/video_filter_registry.dart';
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

  static const screenKey = Key('emulator-display-screen');

  final ui.Image? image;

  final int imageWidth;
  final int imageHeight;

  final int? textureId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final nes = ref.watch(nesStateProvider);

    final shaderState = ref.watch(videoFilterRegistryProvider);

    return LayoutBuilder(
      builder: (_, constraints) {
        final region = settings.region ?? Region.ntsc;
        final overscan = settings.overscan;
        final pixelAspectRatio = _calculatePixelAspectRatio(
          settings,
          constraints,
          region,
        );

        final geometry = calculateDisplayGeometry(
          constraints: constraints,
          visibleWidth: overscan.visibleWidth(imageWidth),
          visibleHeight: overscan.visibleHeight(imageHeight),
          pixelAspectRatio: pixelAspectRatio,
          scaling: settings.scaling,
        );

        final scale = geometry.scale;
        final scaledSize = geometry.scaledSize;

        final narrow = constraints.maxWidth < constraints.maxHeight;

        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

        final anchorAtTop = settings.showTouchControls && narrow;

        final center = Offset(
          canvasSize.width / 2,
          anchorAtTop ? (canvasSize.height / 4 + 40) : canvasSize.height / 2,
        );

        final topLeft =
            center - Offset(scaledSize.width / 2, scaledSize.height / 2);

        Offset? nesPosition(Offset localPosition) => nesPositionFromDisplay(
          displayPosition: localPosition - topLeft,
          scale: scale,
          pixelAspectRatio: pixelAspectRatio,
          imageWidth: imageWidth,
          imageHeight: imageHeight,
          overscan: overscan,
        );

        final baseLayer = textureId != null
            ? frameTextureLayer(
                textureId: textureId!,
                imageWidth: imageWidth,
                imageHeight: imageHeight,
                filters: settings.videoFilters,
                shaders: shaderState.shaders,
                crtFilter: settings.crtFilter,
                shaderFilterSupported: ui.ImageFilter.isShaderFilterSupported,
                imageFilterFactory: ui.ImageFilter.shader,
                overscan: overscan,
              )
            : CustomPaint(
                painter: frameBasePainter(
                  image: image!,
                  filters: settings.videoFilters,
                  shaders: shaderState.shaders,
                  crtFilter: settings.crtFilter,
                  overscan: overscan,
                ),
                child: const SizedBox.expand(),
              );

        final overlayLayer = CustomPaint(
          painter: EmulatorOverlayPainter(
            scale: scale,
            pixelAspectRatio: pixelAspectRatio,
            overscan: overscan,
            showBorder: settings.showBorder,
            paused: nes?.paused ?? false,
            fastForward: nes?.fastForward ?? false,
            rewind: nes?.rewind ?? false,
            crossHairPosition: nes?.hasZapper == true
                ? nes?.zapperPosition
                : null,
          ),
          child: const SizedBox.expand(),
        );

        final screen = SizedBox(
          key: screenKey,
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
                nes?.setZapperPosition(nesPosition(event.localPosition));
              },
              child: GestureDetector(
                onTapDown: (details) {
                  final position = nesPosition(details.localPosition);

                  if (position == null) {
                    return;
                  }

                  nes?.setZapperPosition(position);
                  nes?.zapperPull();
                },
                onTapUp: (details) {
                  final position = nesPosition(details.localPosition);

                  if (position != null) {
                    nes?.setZapperPosition(position);
                  }

                  nes?.zapperRelease();
                },
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  double _calculatePixelAspectRatio(
    Settings settings,
    BoxConstraints constraints,
    Region region,
  ) {
    return switch (settings.pixelAspectRatio) {
      .auto => switch (region) {
        .ntsc => 8 / 7,
        .pal => 11 / 8,
      },
      .ntsc => 8 / 7,
      .pal => 11 / 8,
      .square => 1,
      .stretch => constraints.maxWidth / constraints.maxHeight,
      .custom => settings.customPixelAspectRatio,
    };
  }
}

Widget frameTextureLayer({
  required int textureId,
  required int imageWidth,
  required int imageHeight,
  required List<VideoFilter> filters,
  required Map<VideoFilter, ui.FragmentShader> shaders,
  required CrtFilterSettings crtFilter,
  required bool shaderFilterSupported,
  required ui.ImageFilter Function(ui.FragmentShader shader) imageFilterFactory,
  Overscan overscan = Overscan.none,
}) {
  final texture = OverscanCrop(
    overscan: overscan,
    imageWidth: imageWidth,
    imageHeight: imageHeight,
    child: SizedBox.expand(
      child: Texture(textureId: textureId, filterQuality: FilterQuality.none),
    ),
  );

  if (!shaderFilterSupported) {
    return texture;
  }

  final chain = [
    for (final filter in filters)
      if (shaders[filter] case final shader?) (filter: filter, shader: shader),
  ];

  if (chain.isEmpty) {
    return texture;
  }

  final visibleWidth = overscan.visibleWidth(imageWidth);
  final visibleHeight = overscan.visibleHeight(imageHeight);

  ui.ImageFilter? composed;

  for (final stage in chain) {
    configureVideoFilterShader(
      stage.shader,
      filter: stage.filter,
      sourceWidth: visibleWidth.toDouble(),
      sourceHeight: visibleHeight.toDouble(),
      crtFilter: crtFilter,
    );

    final stageFilter = imageFilterFactory(stage.shader);

    composed = composed == null
        ? stageFilter
        : ui.ImageFilter.compose(outer: stageFilter, inner: composed);
  }

  final chainKey = chain.map((stage) => stage.filter.name).join('+');

  return ImageFiltered(
    key: ValueKey((chainKey, crtFilter, visibleWidth, visibleHeight)),
    imageFilter: composed!,
    child: texture,
  );
}

CustomPainter frameBasePainter({
  required ui.Image image,
  required List<VideoFilter> filters,
  required Map<VideoFilter, ui.FragmentShader> shaders,
  required CrtFilterSettings crtFilter,
  Overscan overscan = Overscan.none,
}) {
  final sourceRect = overscan.visibleRect(image.width, image.height);

  for (final filter in videoFilterOrder.reversed) {
    if (!filters.contains(filter)) {
      continue;
    }

    final shader = shaders[filter];

    if (shader != null) {
      return ShaderFramePainter(
        image: image,
        shader: shader,
        parameters: videoFilterUniforms(filter, crtFilter),
        sourceRect: sourceRect,
      );
    }
  }

  return CpuFramePainter(image: image, sourceRect: sourceRect);
}
