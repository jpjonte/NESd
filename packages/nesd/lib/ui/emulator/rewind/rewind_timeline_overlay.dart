import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/nes/region.dart';
import 'package:nesd/ui/common/hints/input_hint_bar.dart';
import 'package:nesd/ui/emulator/display_geometry.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/input/input_hint_resolver.dart';
import 'package:nesd/ui/emulator/input/input_method.dart';
import 'package:nesd/ui/emulator/overscan.dart';
import 'package:nesd/ui/emulator/overscan_crop.dart';
import 'package:nesd/ui/emulator/rewind/rewind_filmstrip_painter.dart';
import 'package:nesd/ui/emulator/rewind/rewind_scrub_controller.dart';
import 'package:nesd/ui/emulator/video_filter/video_filter_chain.dart';
import 'package:nesd/ui/emulator/video_filter/video_filter_registry.dart';
import 'package:nesd/ui/settings/settings.dart';

const _maxFilmHeight = 120.0;
const _minFilmHeight = 60.0;

const _filmHeightRatio = 1 / 12;

const _overlayColor = Color(0xcc000000);
const _overlayEdgeColor = Colors.white24;
const _textColor = Colors.white;
const _labelColor = Colors.white70;
const _labelFontSize = 11.0;
const _hintRunSpacing = 6.0;

const _frameWidth = 256;
const _frameHeight = 240;

const _dragPreviewFadeDuration = Duration(milliseconds: 200);

class RewindTimelineOverlay extends ConsumerStatefulWidget {
  const RewindTimelineOverlay({super.key});

  @override
  ConsumerState<RewindTimelineOverlay> createState() =>
      _RewindTimelineOverlayState();
}

class _RewindTimelineOverlayState extends ConsumerState<RewindTimelineOverlay> {
  bool _showPreview = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rewindScrubControllerProvider);

    if (!state.open) {
      return const SizedBox.shrink();
    }

    if (!state.settled) {
      _showPreview = true;
    }

    final controller = ref.read(rewindScrubControllerProvider.notifier);

    return Positioned.fill(
      child: Stack(
        children: [
          if (_showPreview)
            AnimatedOpacity(
              opacity: state.settled ? 0 : 1,
              duration: _dragPreviewFadeDuration,
              onEnd: () {
                if (state.settled) {
                  setState(() => _showPreview = false);
                }
              },
              child: RewindDragPreview(state: state),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: RewindFilmstrip(
              state: state,
              secondsBack: controller.secondsBack,
              onScrubBy: controller.moveBy,
              onCommit: controller.commit,
              onCancel: controller.cancel,
            ),
          ),
        ],
      ),
    );
  }
}

class RewindDragPreview extends ConsumerWidget {
  const RewindDragPreview({
    required this.state,
    this.shaderFilterSupported,
    this.imageFilterFactory,
    super.key,
  });

  static const previewKey = Key('rewind-drag-preview');

  static const imageKey = Key('rewind-drag-preview-image');

  final RewindScrubState state;

  final bool? shaderFilterSupported;
  final ui.ImageFilter Function(ui.FragmentShader shader)? imageFilterFactory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = _nearestThumbnail();

    if (image == null) {
      return const SizedBox.shrink();
    }

    final settings = ref.watch(settingsControllerProvider);
    final region = settings.region ?? Region.ntsc;
    final overscan = settings.overscan;

    return LayoutBuilder(
      builder: (context, constraints) {
        final geometry = calculateDisplayGeometry(
          constraints: constraints,
          visibleWidth: overscan.visibleWidth(_frameWidth),
          visibleHeight: overscan.visibleHeight(_frameHeight),
          pixelAspectRatio: calculatePixelAspectRatio(
            pixelAspectRatio: settings.pixelAspectRatio,
            customPixelAspectRatio: settings.customPixelAspectRatio,
            region: region,
            constraints: constraints,
          ),
          scaling: settings.scaling,
          showTouchControls: settings.showTouchControls,
        );

        return Stack(
          children: [
            Positioned(
              left: geometry.topLeft.dx,
              top: geometry.topLeft.dy,
              width: geometry.scaledSize.width,
              height: geometry.scaledSize.height,
              child: KeyedSubtree(
                key: previewKey,
                child: _filtered(
                  ref,
                  overscan: overscan,
                  child: OverscanCrop(
                    overscan: overscan,
                    imageWidth: _frameWidth,
                    imageHeight: _frameHeight,
                    child: SizedBox.expand(
                      child: RawImage(
                        key: imageKey,
                        image: image,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.low,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _filtered(
    WidgetRef ref, {
    required Overscan overscan,
    required Widget child,
  }) {
    final settings = ref.watch(settingsControllerProvider);
    final chain = composeVideoFilterChain(
      filters: settings.videoFilters,
      shaders: ref.watch(videoFilterRegistryProvider).shaders,
      crtFilter: settings.crtFilter,
      shaderFilterSupported:
          shaderFilterSupported ?? ui.ImageFilter.isShaderFilterSupported,
      imageFilterFactory: imageFilterFactory ?? ui.ImageFilter.shader,
      sourceWidth: overscan.visibleWidth(_frameWidth),
      sourceHeight: overscan.visibleHeight(_frameHeight),
    );

    if (chain == null) {
      return child;
    }

    return ImageFiltered(
      key: ValueKey(chain.key),
      imageFilter: chain.filter,
      child: child,
    );
  }

  ui.Image? _nearestThumbnail() {
    final thumbnails = state.thumbnails;

    if (thumbnails.isEmpty) {
      return null;
    }

    final sequences = state.thumbnailSequences;
    var nearest = 0;
    var nearestDistance = (sequences[0] - state.cursorSequence).abs();

    for (var i = 1; i < sequences.length; i++) {
      final distance = (sequences[i] - state.cursorSequence).abs();

      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = i;
      }
    }

    return thumbnails[nearest];
  }
}

class RewindFilmstrip extends StatefulWidget {
  const RewindFilmstrip({
    required this.state,
    required this.secondsBack,
    required this.onScrubBy,
    required this.onCommit,
    required this.onCancel,
    super.key,
  });

  final RewindScrubState state;
  final double Function(int sequence) secondsBack;

  final ValueChanged<int> onScrubBy;

  final VoidCallback onCommit;
  final VoidCallback onCancel;

  @override
  State<RewindFilmstrip> createState() => _RewindFilmstripState();
}

class _RewindFilmstripState extends State<RewindFilmstrip> {
  double _pendingCaptures = 0;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final filmHeight = (width * _filmHeightRatio).clamp(
          _minFilmHeight,
          _maxFilmHeight,
        );

        final seconds = widget
            .secondsBack(state.cursorSequence)
            .toStringAsFixed(1);

        final labelStyle = DefaultTextStyle.of(
          context,
        ).style.copyWith(color: _labelColor, fontSize: _labelFontSize);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (_) => _pendingCaptures = 0,
          onHorizontalDragUpdate: (details) =>
              _scrub(details.delta.dx, filmHeight),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: _overlayColor,
              border: Border(top: BorderSide(color: _overlayEdgeColor)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: DefaultTextStyle(
                  style: DefaultTextStyle.of(
                    context,
                  ).style.copyWith(color: _textColor),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '-${seconds}s',
                        style: const TextStyle(
                          color: _textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        height: filmHeight + rewindFilmstripRulerHeight,
                        child: LayoutBuilder(
                          builder: (context, filmConstraints) =>
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTapUp: (details) => _jumpTo(
                                  details.localPosition.dx,
                                  filmConstraints.maxWidth,
                                  filmHeight,
                                ),
                                child: CustomPaint(
                                  painter: RewindFilmstripPainter(
                                    state: state,
                                    secondsBack: widget.secondsBack,
                                    labelStyle: labelStyle,
                                  ),
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ExcludeFocus(
                        child: _HintBar(
                          captureInterval: state.captureInterval,
                          onCommit: widget.onCommit,
                          onCancel: widget.onCancel,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _jumpTo(double x, double width, double filmHeight) {
    final cellWidth = rewindFilmstripCellWidth(filmHeight);

    if (cellWidth <= 0) {
      return;
    }

    final stride = rewindFilmstripSlotStride(widget.state);
    final captures = ((x - width / 2) * stride / cellWidth).round();

    if (captures == 0) {
      return;
    }

    _pendingCaptures = 0;

    widget.onScrubBy(captures);
  }

  void _scrub(double dx, double filmHeight) {
    final cellWidth = rewindFilmstripCellWidth(filmHeight);

    if (cellWidth <= 0) {
      return;
    }

    final stride = rewindFilmstripSlotStride(widget.state);

    _pendingCaptures += -dx * stride / cellWidth;

    final captures = _pendingCaptures.truncate();

    if (captures == 0) {
      return;
    }

    _pendingCaptures -= captures;

    widget.onScrubBy(captures);
  }
}

class _HintBar extends ConsumerWidget {
  const _HintBar({
    required this.captureInterval,
    required this.onCommit,
    required this.onCancel,
  });

  final int captureInterval;
  final VoidCallback onCommit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final touch = ref.watch(
      inputHintResolverProvider.select(
        (resolver) => resolver.method == InputMethod.touch,
      ),
    );

    final hints = [
      const InputHint(
        actions: [inputLeft, inputRight],
        label: 'Skip 1 second · hold to speed up',
      ),
      InputHint(
        actions: const [inputUp, previousInput, inputDown, nextInput],
        label: _fineStepLabel(captureInterval),
      ),
      InputHint(
        actions: const [confirm],
        icon: Icons.play_arrow,
        label: 'Resume here',
        onPressed: onCommit,
      ),
      InputHint(
        actions: const [cancel],
        icon: Icons.close,
        label: 'Back to live',
        onPressed: onCancel,
      ),
    ];

    if (!touch) {
      return InputHintBar(hints: hints, color: _textColor);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Drag the strip to scrub · Tap a frame to jump there',
          style: TextStyle(color: _labelColor, fontSize: _labelFontSize),
        ),
        const SizedBox(height: _hintRunSpacing),
        InputHintBar(hints: hints, color: _textColor),
      ],
    );
  }

  static String _fineStepLabel(int captureInterval) =>
      switch (captureInterval) {
        1 => 'Step 1 frame',
        final frames => 'Step $frames frames',
      };
}
