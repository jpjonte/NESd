import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/nes/region.dart';
import 'package:nesd/ui/emulator/display_geometry.dart';
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

const _hintFillColor = Colors.white12;
const _hintBorderRadius = BorderRadius.all(Radius.circular(6));
const _hintPadding = EdgeInsets.symmetric(horizontal: 10, vertical: 4);
const _hintMinHeight = 32.0;
const _touchHintMinHeight = 44.0;
const _hintIconSize = 16.0;
const _hintSpacing = 12.0;
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

    final touchHints = ref.watch(
      settingsControllerProvider.select(
        (settings) => settings.showTouchControls,
      ),
    );

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
              touchHints: touchHints,
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
    required this.touchHints,
    super.key,
  });

  final RewindScrubState state;
  final double Function(int sequence) secondsBack;

  final ValueChanged<int> onScrubBy;

  final VoidCallback onCommit;
  final VoidCallback onCancel;

  final bool touchHints;

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
                        child: CustomPaint(
                          painter: RewindFilmstripPainter(
                            state: state,
                            secondsBack: widget.secondsBack,
                            labelStyle: labelStyle,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ExcludeFocus(
                        child: _HintBar(
                          captureInterval: state.captureInterval,
                          onCommit: widget.onCommit,
                          onCancel: widget.onCancel,
                          touchHints: widget.touchHints,
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

class _HintBar extends StatelessWidget {
  const _HintBar({
    required this.captureInterval,
    required this.onCommit,
    required this.onCancel,
    required this.touchHints,
  });

  final int captureInterval;
  final VoidCallback onCommit;
  final VoidCallback onCancel;
  final bool touchHints;

  @override
  Widget build(BuildContext context) {
    if (touchHints) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Drag the strip to scrub · Tap a frame to jump there',
            style: TextStyle(color: _labelColor, fontSize: _labelFontSize),
          ),
          const SizedBox(height: _hintRunSpacing),
          _HintRow(
            children: [
              _HintChip(
                prompt: const _HintIcon(Icons.play_arrow),
                label: 'Resume here',
                minHeight: _touchHintMinHeight,
                onPressed: onCommit,
              ),
              _HintChip(
                prompt: const _HintIcon(Icons.close),
                label: 'Back to live',
                minHeight: _touchHintMinHeight,
                onPressed: onCancel,
              ),
            ],
          ),
        ],
      );
    }

    return _HintRow(
      children: [
        const _HintChip(
          prompt: _ArrowPrompt(Icons.arrow_left, Icons.arrow_right),
          label: 'Skip 1 second · hold to speed up',
        ),
        _HintChip(
          prompt: const _ArrowPrompt(
            Icons.arrow_drop_up,
            Icons.arrow_drop_down,
          ),
          label: _fineStepLabel(captureInterval),
        ),
        _HintChip(
          prompt: const _KeyPrompt(Icons.play_arrow, 'Confirm'),
          label: 'Resume here',
          onPressed: onCommit,
        ),
        _HintChip(
          prompt: const _KeyPrompt(Icons.close, 'Cancel'),
          label: 'Back to live',
          onPressed: onCancel,
        ),
      ],
    );
  }

  static String _fineStepLabel(int captureInterval) =>
      switch (captureInterval) {
        1 => 'Step 1 frame',
        final frames => 'Step $frames frames',
      };
}

class _HintRow extends StatelessWidget {
  const _HintRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: _hintSpacing,
      runSpacing: _hintRunSpacing,
      children: children,
    );
  }
}

class _HintIcon extends StatelessWidget {
  const _HintIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, color: _textColor, size: _hintIconSize);
  }
}

class _HintChip extends StatelessWidget {
  const _HintChip({
    required this.prompt,
    required this.label,
    this.minHeight = _hintMinHeight,
    this.onPressed,
  });

  final Widget prompt;
  final String label;
  final double minHeight;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _hintFillColor,
      borderRadius: _hintBorderRadius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: _hintBorderRadius,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Padding(
            padding: _hintPadding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                prompt,
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: _labelColor,
                    fontSize: _labelFontSize,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArrowPrompt extends StatelessWidget {
  const _ArrowPrompt(this.first, this.second);

  final IconData first;
  final IconData second;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [_HintIcon(first), _HintIcon(second)],
    );
  }
}

class _KeyPrompt extends StatelessWidget {
  const _KeyPrompt(this.icon, this.name);

  final IconData icon;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HintIcon(icon),
        const SizedBox(width: 4),
        Text(
          name,
          style: const TextStyle(
            color: _textColor,
            fontSize: _labelFontSize,
            fontVariations: [FontVariation.weight(700)],
          ),
        ),
      ],
    );
  }
}
