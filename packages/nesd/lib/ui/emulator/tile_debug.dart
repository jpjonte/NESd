import 'package:flutter/material.dart';

// TEMPORARY: the tile viewer read PPU memory directly from the NES, which now
// lives in the emulator isolate. Will be reconnected through the isolate
// protocol (TileDebugRequest/TileDebugResponse); until then the panel renders
// an inert empty state.
class TileDebugWidget extends StatelessWidget {
  const TileDebugWidget({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
