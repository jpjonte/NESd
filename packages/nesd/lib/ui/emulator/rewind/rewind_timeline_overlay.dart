import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/emulator/rewind/rewind_filmstrip_painter.dart';
import 'package:nesd/ui/emulator/rewind/rewind_scrub_controller.dart';

const _maxFilmHeight = 120.0;
const _minFilmHeight = 60.0;

const _filmHeightRatio = 1 / 12;

const _overlayColor = Color(0xcc000000);
const _overlayEdgeColor = Colors.white24;
const _textColor = Colors.white;
const _labelColor = Colors.white70;
const _labelFontSize = 11.0;

class RewindTimelineOverlay extends ConsumerWidget {
  const RewindTimelineOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rewindScrubControllerProvider);

    if (!state.open) {
      return const SizedBox.shrink();
    }

    final controller = ref.read(rewindScrubControllerProvider.notifier);

    return Positioned(
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
    );
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
