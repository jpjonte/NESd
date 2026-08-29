import 'package:flutter/material.dart';
import 'package:nesd/ui/emulator/frame_graph_history.dart';
import 'package:nesd/ui/emulator/frame_graph_painter.dart';

class FrameGraph extends StatelessWidget {
  const FrameGraph({required this.history, super.key});

  final FrameGraphHistory history;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: SizedBox(
        width: double.infinity,
        height: frameGraphHeight,
        child: CustomPaint(painter: FrameGraphPainter(history: history)),
      ),
    );
  }
}
