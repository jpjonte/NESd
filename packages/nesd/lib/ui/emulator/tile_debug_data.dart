import 'package:flutter/foundation.dart';

// register names don't follow dart naming conventions
// ignore_for_file: non_constant_identifier_names

/// Immutable snapshot of PPU state for the tile-debug screen, decoded from a
/// `TileDebugResponse` fetched over the emulator isolate's request/response
/// protocol.
///
/// The six bit-math getters below are transplanted verbatim from
/// `PPUCTRL_B`/`PPUCTRL_X`/`PPUCTRL_Y`/`t_coarseX`/`t_coarseY`/`t_fineY` in
/// `lib/nes/ppu/ppu.dart`, reading this class's own `ppuCtrl`/`t` fields
/// instead of the PPU's live registers.
@immutable
class TileDebugData {
  const TileDebugData({
    required this.ppuMemory,
    required this.ppuCtrl,
    required this.v,
    required this.t,
    required this.x,
  });

  /// 16KB PPU memory dump; index = PPU address.
  final Uint8List ppuMemory;

  final int ppuCtrl;
  final int v;
  final int t;
  final int x;

  int ppuRead(int address) => ppuMemory[address & 0x3fff];

  int get PPUCTRL_B => (ppuCtrl >> 4) & 1; // background pattern table address
  int get PPUCTRL_X => ppuCtrl & 1; // scroll X high bit
  int get PPUCTRL_Y => (ppuCtrl >> 1) & 1; // scroll Y high bit

  int get t_coarseX => t & 0x1F;
  int get t_coarseY => (t >> 5) & 0x1F;
  int get t_fineY => (t >> 12) & 0x7;
}
