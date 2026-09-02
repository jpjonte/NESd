// register names don't follow dart naming conventions
// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/ppu/four_bpp_address.dart';
import 'package:nesd/nes/ppu/frame_buffer.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/nes/ppu/ppu_state.dart';
import 'package:nesd/nes/ppu/sprite_output.dart';
import 'package:nesd/nes/region.dart';

const ntscConsoleCyclesPerCycle = 4;
const palConsoleCyclesPerCycle = 5;

const ntscPreRenderScanline = 261;
const palPreRenderScanline = 311;

const vblankScanline = 241;

const _ppuBlockAddressWidth = 10;
const _ppuBlockSize = 1 << _ppuBlockAddressWidth;
const _ppuBlockMask = _ppuBlockSize - 1;
const _ppuBlockCount = 0x4000 ~/ _ppuBlockSize;

class PPU {
  PPU(this.bus);

  final Bus bus;

  int PPUCTRL = 0x00;
  int PPUMASK = 0x00;
  int PPUSTATUS = 0x00;
  int OAMADDR = 0x00;
  int OAMDATA = 0x00;
  int PPUSCROLL = 0x00;
  int PPUDATA = 0x00;

  // during rendering: scroll position, outside rendering: VRAM address
  int v = 0;
  // during rendering: starting coarse X scroll, starting Y scroll
  // outside rendering: scroll or VRAM address
  int t = 0;
  // fine X scroll
  int x = 0;
  // first or second write toggle
  int w = 0;

  int get v_coarseScroll => v & 0x3ff; // tile X and Y
  int get v_coarseX => v & 0x1F; // tile X
  int get v_coarseY => (v >> 5) & 0x1F; // tile Y
  int get v_nametable => (v >> 10) & 0x3;
  int get v_nametableX => (v >> 10) & 0x1;
  int get v_nametableY => (v >> 11) & 0x1;
  int get v_fineY => (v >> 12) & 0x7;

  set v_coarseX(int value) => v = (v & 0xFFE0) | (value & 0x1F);
  set v_coarseY(int value) => v = (v & 0xFC1F) | ((value & 0x1F) << 5);
  set v_nametableX(int value) => v = v.setBit(10, value);
  set v_nametableY(int value) => v = v.setBit(11, value);
  set v_fineY(int value) => v = (v & 0x0FFF) | ((value & 0x7) << 12);

  int get t_coarseX => t & 0x1F;
  int get t_coarseY => (t >> 5) & 0x1F;
  int get t_nametableX => (t >> 10) & 0x1;
  int get t_nametableY => (t >> 11) & 0x1;
  int get t_fineY => (t >> 12) & 0x7;

  int get PPUCTRL_N => PPUCTRL & 0x3; // nametable address
  int get PPUCTRL_I => (PPUCTRL >> 2) & 1; // VRAM address increment
  int get PPUCTRL_S => (PPUCTRL >> 3) & 1; // sprite pattern table address (8x8)
  int get PPUCTRL_B => (PPUCTRL >> 4) & 1; // background pattern table address
  int get PPUCTRL_H => (PPUCTRL >> 5) & 1; // sprite size
  int get PPUCTRL_X => PPUCTRL & 1; // scroll X high bit
  int get PPUCTRL_Y => (PPUCTRL >> 1) & 1; // scroll Y high bit

  int get PPUMASK_Gr => PPUMASK & 1; // greyscale
  int get PPUMASK_ER => (PPUMASK >> 5) & 1; // emphasize red
  int get PPUMASK_EG => (PPUMASK >> 6) & 1; // emphasize green
  int get PPUMASK_EB => (PPUMASK >> 7) & 1; // emphasize blue

  int get PPUSTATUS_O => (PPUSTATUS >> 5) & 1; // sprite overflow
  int get PPUSTATUS_S => (PPUSTATUS >> 6) & 1; // sprite 0 hit
  int get PPUSTATUS_V => (PPUSTATUS >> 7) & 1; // vblank active

  set PPUSTATUS_O(int value) => PPUSTATUS = PPUSTATUS.setBit(5, value);
  set PPUSTATUS_S(int value) => PPUSTATUS = PPUSTATUS.setBit(6, value);
  set PPUSTATUS_V(int value) => PPUSTATUS = PPUSTATUS.setBit(7, value);

  final Uint8List ram = Uint8List(0x0800);
  final Uint8List oam = Uint8List(0x0100);
  final Uint8List secondaryOam = Uint8List(0x20);
  late final Uint32List _secondaryOamWords = secondaryOam.buffer.asUint32List();
  final Uint8List palette = Uint8List(0x100);
  // Precomputed final RGB colors per palette entry
  // (greyscale + emphasis already applied)
  final Uint32List _paletteLut = Uint32List(0x80);

  Uint32List _systemPalette = defaultPalette;

  Region _region = Region.ntsc;

  int _emphasisBase = 0;

  @visibleForTesting
  Uint32List get paletteLut => _paletteLut;

  Uint32List get systemPalette => _systemPalette;

  set systemPalette(Uint32List value) {
    if (value.length != nesPaletteLength) {
      throw ArgumentError.value(
        value.length,
        'value',
        'expected $nesPaletteLength entries',
      );
    }

    _systemPalette = value;

    _rebuildPaletteLut();
  }

  final FrameBuffer frameBuffer = FrameBuffer(width: 256, height: 240);
  final List<Uint8List?> _ppuBlocks = List<Uint8List?>.filled(
    _ppuBlockCount,
    null,
  );

  /// Block table for the VT03+ 16 KiB 4bpp pattern space.
  final List<Uint8List?> _fourBppBlocks = List<Uint8List?>.filled(
    _ppuBlockCount,
    null,
  );

  /// EVA pattern space, 2bpp view: 8 EVA x 8 blocks.
  final List<Uint8List?> _evaBlocks2bpp = List<Uint8List?>.filled(64, null);

  /// EVA pattern space, 4bpp view: 8 EVA x 16 blocks.
  final List<Uint8List?> _evaBlocks4bpp = List<Uint8List?>.filled(128, null);

  bool _showBackground = false;
  bool _showSprites = false;

  int decay = 0;

  final List<int> decayRefreshedAt = List<int>.filled(8, 0);

  static const _decayFrames = 36;

  bool _renderingAtSkipDecision = false;
  bool _showLeftBackground = false;
  bool _showLeftSprites = false;
  bool _nmiEnabled = false;

  int _consoleCyclesPerCycle = ntscConsoleCyclesPerCycle;
  int consoleCycles = 0;

  /// Set by NES at power-on; skips the empty mapper hook for mappers
  /// that don't watch the PPU address bus.
  bool mapperNeedsPpuAddress = false;

  bool mapperNeedsPpuReads = false;

  bool mapperNeedsExtendedPpuRegisters = false;

  bool extendedPalette = false;

  bool bgFourBpp = false;
  bool spriteFourBpp = false;
  bool wideVideoBus = false;

  bool bgExtension = false;
  bool spriteExtension = false;
  bool spriteSixteenPixels = false;

  int bgEvaBit2 = 0;
  int vrwb = 0;

  int cycles = 0;
  int cycle = 0;
  int scanline = 0;
  int frames = 0;

  int _preRenderScanline = ntscPreRenderScanline;

  int get preRenderScanline => _preRenderScanline;

  int _pixelBase = 0;

  int nametableLatch = 0;

  int patternTableHighLatch = 0;
  int patternTableLowLatch = 0;

  int patternTableHigh2Latch = 0;
  int patternTableLow2Latch = 0;

  int attributeTableLatch = 0;

  int attribute = 0;

  /// Decoded background pixels for the two tiles currently held by the
  /// shift registers.
  final Uint8List _bgWindow = Uint8List(16);

  /// Shifts since the window was last rebuilt.
  int _bgWindowPos = 0;

  // Cached pattern table base for background when using 8x8 sprites.
  int _bgPatternBase = 0;

  int oamAddress = 0;
  int oamBuffer = 0;

  int spriteCount = 0;
  int secondarySpriteCount = 0;

  int _spriteRangeMinY = 0;

  bool sprite0OnNextLine = false;
  bool sprite0OnCurrentLine = false;

  final _spriteOutputs = List.generate(8, (_) => SpriteOutput());

  /// Sprite data for each pixel of the current scanline (built in cycle 321)
  /// bits 0-3 = pattern
  /// bit 4 = priority
  /// bits 5-6 = attribute in the 4bpp position (zero in 2bpp entries)
  /// bit 7 = opaque pixel of sprite 0
  final Uint8List _spriteLine = Uint8List(256);

  PPUState get state => PPUState(
    PPUCTRL: PPUCTRL,
    PPUMASK: PPUMASK,
    PPUSTATUS: PPUSTATUS,
    OAMADDR: OAMADDR,
    OAMDATA: OAMDATA,
    PPUSCROLL: PPUSCROLL,
    PPUDATA: PPUDATA,
    v: v,
    t: t,
    x: x,
    w: w,
    ram: ram,
    oam: oam,
    secondaryOam: secondaryOam,
    palette: palette,
    frameBuffer: frameBuffer,
    consoleCycles: consoleCycles,
    cycles: cycles,
    cycle: cycle,
    scanline: scanline,
    frames: frames,
    nametableLatch: nametableLatch,
    patternTableHighLatch: patternTableHighLatch,
    patternTableLowLatch: patternTableLowLatch,
    bgWindow: _normalizedWindow(),
    patternTableLow2Latch: patternTableLow2Latch,
    patternTableHigh2Latch: patternTableHigh2Latch,
    attributeTableLatch: attributeTableLatch,
    attribute: attribute,
    oamAddress: oamAddress,
    oamBuffer: oamBuffer,
    spriteCount: spriteCount,
    secondarySpriteCount: secondarySpriteCount,
    sprite0OnNextLine: sprite0OnNextLine,
    sprite0OnCurrentLine: sprite0OnCurrentLine,
    decay: decay,
    decayRefreshedAt: decayRefreshedAt,
    spriteOutputs: _spriteOutputs.map((e) => e.state).toList(),
  );

  set state(PPUState state) {
    PPUCTRL = state.PPUCTRL;
    PPUMASK = state.PPUMASK;
    PPUSTATUS = state.PPUSTATUS;
    OAMADDR = state.OAMADDR;
    OAMDATA = state.OAMDATA;
    PPUSCROLL = state.PPUSCROLL;
    PPUDATA = state.PPUDATA;
    v = state.v;
    t = state.t;
    x = state.x;
    w = state.w;
    ram.setAll(0, state.ram);
    oam.setAll(0, state.oam);
    secondaryOam.setAll(0, state.secondaryOam);
    palette.setAll(0, state.palette);
    if (state.frameBuffer case final frame?) {
      frameBuffer.setPixels(frame.presentedPixels);
    }
    consoleCycles = state.consoleCycles;
    cycles = state.cycles;
    cycle = state.cycle;
    scanline = state.scanline;
    frames = state.frames;
    _pixelBase = scanline * frameBuffer.width;
    _scanlinePhase = _phaseForScanline();
    nametableLatch = state.nametableLatch;
    patternTableHighLatch = state.patternTableHighLatch;
    patternTableLowLatch = state.patternTableLowLatch;
    attributeTableLatch = state.attributeTableLatch;
    attribute = state.attribute;

    if (state.bgWindow case final bgWindow?) {
      _bgWindow.setAll(0, bgWindow);
      _bgWindowPos = 0;
    } else {
      _rebuildWindowFromShiftRegisters(
        state.patternTableHighShift,
        state.patternTableLowShift,
        state.attributeTableHighShift,
        state.attributeTableLowShift,
        state.attribute,
      );
    }

    patternTableLow2Latch = state.patternTableLow2Latch;
    patternTableHigh2Latch = state.patternTableHigh2Latch;

    oamAddress = state.oamAddress;
    oamBuffer = state.oamBuffer;
    spriteCount = state.spriteCount;
    secondarySpriteCount = state.secondarySpriteCount;
    sprite0OnNextLine = state.sprite0OnNextLine;
    sprite0OnCurrentLine = state.sprite0OnCurrentLine;

    decay = state.decay;

    for (var bit = 0; bit < 8; bit++) {
      decayRefreshedAt[bit] = state.decayRefreshedAt[bit];
    }

    for (var i = 0; i < _spriteOutputs.length; i++) {
      _spriteOutputs[i].state = state.spriteOutputs[i];
    }

    _nmiEnabled = (PPUCTRL & 0x80) != 0;
    _bgPatternBase = (PPUCTRL_B & 1) << 12;
    _updateMaskFlags();

    _renderingAtSkipDecision = _showBackground || _showSprites;

    _rebuildPaletteLut();

    _rasterizeSpriteLine();
  }

  // we don't need a getter from this
  // ignore: avoid_setters_without_getters
  set region(Region region) {
    _region = region;

    switch (region) {
      case Region.ntsc:
        _consoleCyclesPerCycle = ntscConsoleCyclesPerCycle;
        _preRenderScanline = ntscPreRenderScanline;
      case Region.pal:
        _consoleCyclesPerCycle = palConsoleCyclesPerCycle;
        _preRenderScanline = palPreRenderScanline;
    }

    // The phase depends on _preRenderScanline; a live mid-game region
    // switch must not run a stale phase for the rest of the scanline.
    _scanlinePhase = _phaseForScanline();

    _rebuildPaletteLut();
  }

  void reset() {
    consoleCycles = 0;
    cycles = 0;
    cycle = 0;
    scanline = 0;
    frames = 0;
    _scanlinePhase = _phaseForScanline();

    PPUCTRL = 0x00;
    PPUMASK = 0x00;
    PPUSTATUS = 0x00;
    OAMADDR = 0x00;
    OAMDATA = 0x00;
    PPUSCROLL = 0x00;
    PPUDATA = 0x00;

    v = 0;
    t = 0;
    x = 0;
    w = 0;

    nametableLatch = 0;
    patternTableHighLatch = 0;
    patternTableLowLatch = 0;
    patternTableHigh2Latch = 0;
    patternTableLow2Latch = 0;
    attributeTableLatch = 0;
    attribute = 0;

    _bgWindow.fillRange(0, _bgWindow.length, 0);
    _bgWindowPos = 0;

    oamAddress = 0;
    oamBuffer = 0;

    spriteCount = 0;
    secondarySpriteCount = 0;

    sprite0OnNextLine = false;
    sprite0OnCurrentLine = false;

    _rasterizeSpriteLine();

    ram.fillRange(0, ram.length, 0);
    oam.fillRange(0, oam.length, 0);
    secondaryOam.fillRange(0, secondaryOam.length, 0);
    palette.fillRange(0, palette.length, 0);
    _ppuBlocks.fillRange(0, _ppuBlocks.length, null);
    _fourBppBlocks.fillRange(0, _fourBppBlocks.length, null);
    _evaBlocks2bpp.fillRange(0, _evaBlocks2bpp.length, null);
    _evaBlocks4bpp.fillRange(0, _evaBlocks4bpp.length, null);

    _pixelBase = 0;

    _nmiEnabled = false;
    _bgPatternBase = 0;
    _updateMaskFlags();

    _renderingAtSkipDecision = false;

    decay = 0;
    decayRefreshedAt.fillRange(0, 8, 0);

    bgFourBpp = false;
    spriteFourBpp = false;
    wideVideoBus = false;

    bgExtension = false;
    spriteExtension = false;
    spriteSixteenPixels = false;

    bgEvaBit2 = 0;
    vrwb = 0;

    frameBuffer.resetBuffers();

    _rebuildPaletteLut();
  }

  int getPixelBrightness(int x, int y, {bool previousFrame = false}) {
    if (!_showBackground && !_showSprites) {
      return 0;
    }

    return frameBuffer.getPixelBrightness(x, y, previousFrame: previousFrame);
  }

  @pragma('vm:prefer-inline')
  int readPpuMemory(int address, {bool updateBusAddress = true}) {
    if (updateBusAddress) {
      _updateBusAddress(address);
    }

    final maskedAddress = address & 0x3fff;

    if (maskedAddress < 0x3f00 && !mapperNeedsPpuReads) {
      final source = _ppuBlocks[maskedAddress >> _ppuBlockAddressWidth];

      if (source != null) {
        return source[maskedAddress & _ppuBlockMask];
      }
    }

    return bus.ppuRead(maskedAddress);
  }

  void writePpuMemory(int address, int value, {bool updateBusAddress = true}) {
    if (updateBusAddress) {
      _updateBusAddress(address);
    }

    bus.ppuWrite(address, value);
  }

  void _updateBusAddress(int address) {
    if (mapperNeedsPpuAddress) {
      bus.cartridge.mapper.updatePpuAddress(address);
    }
  }

  int readRegister(int address, {bool disableSideEffects = false}) {
    if (mapperNeedsExtendedPpuRegisters) {
      final register = address & 0x1f;

      if (register >= 0x10) {
        return bus.cartridge.mapper.extendedPpuRead(
          0x2000 | register,
          disableSideEffects: disableSideEffects,
        );
      }

      if (register >= 0x08) {
        return _decayValue;
      }

      return _readStockRegister(
        register,
        disableSideEffects: disableSideEffects,
      );
    }

    return _readStockRegister(
      address & 0x07,
      disableSideEffects: disableSideEffects,
    );
  }

  int _readStockRegister(int register, {bool disableSideEffects = false}) {
    return switch (register) {
      2 => _readPPUSTATUS(disableSideEffects: disableSideEffects),
      4 => _readOAMDATA(),
      7 => _readPPUDATA(disableSideEffects: disableSideEffects),
      _ => _decayValue,
    };
  }

  int _readWithDecay(int value, int mask) {
    _refreshDecay(value, mask);

    return (value & mask) | (_decayValue & ~mask & 0xff);
  }

  void _refreshDecay(int value, int mask) {
    for (var bit = 0; bit < 8; bit++) {
      final flag = 1 << bit;

      if (mask & flag == 0) {
        continue;
      }

      decay = (decay & ~flag) | (value & flag);
      decayRefreshedAt[bit] = frames;
    }
  }

  int get _decayValue {
    var value = decay;

    for (var bit = 0; bit < 8; bit++) {
      if (frames - decayRefreshedAt[bit] > _decayFrames) {
        value &= ~(1 << bit);
      }
    }

    return value & 0xff;
  }

  void writeRegister(int address, int value) {
    if (mapperNeedsExtendedPpuRegisters) {
      final register = address & 0x1f;

      if (register >= 0x10) {
        bus.cartridge.mapper.extendedPpuWrite(0x2000 | register, value);

        return;
      }

      if (register >= 0x08) {
        return;
      }

      _writeStockRegister(register, value);

      return;
    }

    _writeStockRegister(address & 0x07, value);
  }

  void _writeStockRegister(int register, int value) {
    _refreshDecay(value, 0xff);

    switch (register) {
      case 0:
        _writePPUCTRL(value);
      case 1:
        _writePPUMASK(value);
      case 3:
        OAMADDR = value;
      case 4:
        _writeOAMDATA(value);
      case 5:
        _writePPUSCROLL(value);
      case 6:
        _writePPUADDR(value);
      case 7:
        _writePPUDATA(value);
    }
  }

  void writeOAM(int offset, int value) {
    oam[(OAMADDR + offset) & 0xFF] = value;
  }

  int get currentX => cycle - 1;

  void stepUntil(int targetCycles) {
    // NTSC: the CPU advances consoleCycles in fixed 3-dot increments, so the
    // common call needs exactly 3 steps. Inlining them removes per-dot
    // loop-condition overhead (~89k calls/frame). PAL (3.2:1) keeps the generic
    // loop below.
    if (_consoleCyclesPerCycle == ntscConsoleCyclesPerCycle &&
        targetCycles - consoleCycles == 3 * ntscConsoleCyclesPerCycle) {
      step();
      step();
      step();

      return;
    }

    while (consoleCycles < targetCycles) {
      step();
    }
  }

  /// Selected once per scanline change; step() calls it directly
  /// instead of re-classifying the scanline every dot.
  late void Function() _scanlinePhase = _phaseForScanline();

  void Function() _phaseForScanline() {
    if (scanline < 240) {
      return _stepVisibleScanline;
    }

    if (scanline == _preRenderScanline) {
      return _stepPreRenderScanline;
    }

    if (scanline == vblankScanline) {
      return _stepVblankLine;
    }

    return _stepIdleScanline;
  }

  void _stepIdleScanline() {}

  void step() {
    _scanlinePhase();

    _updateCounters();
  }

  @pragma('vm:prefer-inline')
  void _stepVisibleScanline() {
    final renderingActive = _showBackground || _showSprites;

    // Sprite evaluation always runs on visible lines
    _evaluateSprites();

    if (renderingActive) {
      // Pixel rendering at cycles 1-256
      if (cycle >= 1 && cycle <= 256) {
        _renderPixel();
        _shiftRegisters();
        _stepFetchCycle();
      } else if (cycle >= 321 && cycle <= 336) {
        // Pre-fetch for next scanline
        _shiftRegisters();
        _stepFetchCycle();
      }

      if (cycle == 256) {
        _incrementY();
      }

      if (cycle == 257) {
        _copyHorizontalBits();
      }
    }

    if (renderingActive && cycle >= 257 && cycle <= 320) {
      OAMADDR = 0x0000;
    }

    // Nametable reads at cycles 337, 339 (regardless of rendering)
    if (cycle == 337 || cycle == 339) {
      readPpuMemory(_nametableAddress());
    }

    // Cycle 0 bus address update
    if (cycle == 0 && renderingActive && (scanline > 0 || frames.isEven)) {
      _updateBusAddress(_nametableAddress());
    }
  }

  @pragma('vm:prefer-inline')
  void _stepPreRenderScanline() {
    final renderingActive = _showBackground || _showSprites;

    if (renderingActive) {
      // Fetch cycles (no pixel rendering on pre-render line)
      if (cycle >= 1 && cycle <= 256) {
        _shiftRegisters();
        _stepFetchCycle();
      } else if (cycle >= 321 && cycle <= 336) {
        _shiftRegisters();
        _stepFetchCycle();
      }

      if (cycle == 256) {
        _incrementY();
      }

      if (cycle == 257) {
        _copyHorizontalBits();
      }

      // Copy vertical bits at cycles 280-304
      if (cycle >= 280 && cycle <= 304) {
        _copyVerticalBits();
      }

      if (cycle >= 257 && cycle <= 320) {
        _fetchSpritesForBusOnly();
      }
    }

    if (renderingActive && cycle >= 257 && cycle <= 320) {
      OAMADDR = 0x0000;
    }

    // Nametable reads at cycles 337, 339 (regardless of rendering)
    if (cycle == 337 || cycle == 339) {
      readPpuMemory(_nametableAddress());
    }

    // Clear status flags at cycle 1
    if (cycle == 1) {
      PPUSTATUS_O = 0;
      PPUSTATUS_S = 0;
      PPUSTATUS_V = 0;

      _updateNmiLine();
    }
  }

  @pragma('vm:prefer-inline')
  void _updateNmiLine() {
    if (PPUSTATUS_V == 1 && _nmiEnabled) {
      bus.triggerNmi();

      return;
    }

    bus.clearNmi();
  }

  @pragma('vm:prefer-inline')
  void _stepVblankLine() {
    // Set vblank flag and trigger NMI at cycle 1
    if (cycle == 1) {
      PPUSTATUS_V = 1;

      spriteCount = 0;
      secondarySpriteCount = 0;

      _spriteLine.fillRange(0, 256, 0);

      _updateNmiLine();
    }

    // Cycle 0 bus address update
    if (cycle == 0) {
      _updateBusAddress(v & 0x3fff);
    }
  }

  @pragma('vm:prefer-inline')
  void _stepFetchCycle() {
    final subcycle = cycle & 7;

    switch (subcycle) {
      case 0:
        _loadShiftRegisters();
        _incrementX();
      case 1:
        _fetchNametable();
      case 3:
        _fetchAttributeTable();
      case 5:
        _fetchPatternTableLow();
      case 7:
        _fetchPatternTableHigh();
    }
  }

  int _readPPUSTATUS({bool disableSideEffects = false}) {
    final value = PPUSTATUS;

    if (disableSideEffects) {
      return (value & 0xe0) | (_decayValue & 0x1f);
    }

    PPUSTATUS_V = 0;
    w = 0;

    _updateNmiLine();

    return _readWithDecay(value, 0xe0);
  }

  int _readOAMDATA() {
    final value = oam[OAMADDR];

    final driven = OAMADDR & 0x3 == 2 ? value & 0xe3 : value;

    return _readWithDecay(driven, 0xff);
  }

  int _readPPUDATA({bool disableSideEffects = false}) {
    // return buffer from last read
    var value = PPUDATA;

    if (!disableSideEffects) {
      PPUDATA = readPpuMemory(v);
    }

    // always return current palette data
    if (v >= 0x3F00) {
      value = PPUDATA;
    }

    final isPalette = v >= 0x3f00;

    if (!disableSideEffects) {
      v += PPUCTRL_I == 0 ? 1 : 32;

      _updateBusAddress(v & 0x3fff);
    }

    if (disableSideEffects) {
      return value;
    }

    return _readWithDecay(value, isPalette ? 0x3f : 0xff);
  }

  void _writePPUCTRL(int value) {
    PPUCTRL = value;

    _nmiEnabled = (value & 0x80) != 0;

    _updateNmiLine();

    t = (t & 0xF3FF) | (PPUCTRL_N << 10);

    // cache pattern table bases (<< 12)
    _bgPatternBase = (PPUCTRL_B & 1) << 12;
  }

  void _writePPUMASK(int value) {
    PPUMASK = value;

    _updateMaskFlags();

    _rebuildPaletteLut();
  }

  void _updateMaskFlags() {
    _showLeftBackground = (PPUMASK & 0x02) != 0;
    _showLeftSprites = (PPUMASK & 0x04) != 0;
    _showBackground = (PPUMASK & 0x08) != 0;
    _showSprites = (PPUMASK & 0x10) != 0;
  }

  void _writeOAMDATA(int value) {
    if ((_showBackground || _showSprites) &&
        scanline < 240 &&
        cycle >= 1 &&
        cycle <= 256) {
      return;
    }

    oam[OAMADDR] = value;

    OAMADDR = (OAMADDR + 1) & 0xff;
  }

  void _writePPUSCROLL(int value) {
    PPUSCROLL = value;

    if (w == 0) {
      // t: ....... ...ABCDE <- d: ABCDE...
      t = (t & 0xFFE0) | (value >> 3);
      // x:              FGH <- d: .....FGH
      x = value & 0x07;
    } else {
      // t: FGH..AB CDE..... <- d: ABCDEFGH
      t = (t & 0xc1f) | ((value & 0xF8) << 2) | ((value & 0x07) << 12);
    }

    w = 1 - w;
  }

  void _writePPUADDR(int value) {
    if (w == 0) {
      // t: .CDEFGH ........ <- d: ..CDEFGH
      // t: Z...... ........ <- 0 (bit Z is cleared)
      t = (t & 0x00FF) | ((value & 0x3F) << 8);
    } else {
      // t: ....... ABCDEFGH <- d: ABCDEFGH
      t = (t & 0xFF00) | value;
      v = t;

      _updateBusAddress(v);
    }

    w = 1 - w;
  }

  void _writePPUDATA(int value) {
    writePpuMemory(v, value);

    v += PPUCTRL_I == 0 ? 1 : 32;

    _updateBusAddress(v & 0x3fff);
  }

  @pragma('vm:prefer-inline')
  void _updateCounters() {
    consoleCycles += _consoleCyclesPerCycle;
    cycles++;
    cycle++;

    if (scanline == _preRenderScanline && cycle == 339) {
      _renderingAtSkipDecision = _showBackground || _showSprites;
    }

    if (scanline == _preRenderScanline &&
        cycle == 340 &&
        frames.isOdd &&
        _renderingAtSkipDecision) {
      scanline = 0;
      cycle = 0;
      frames++;

      _pixelBase = 0;
      _scanlinePhase = _phaseForScanline();

      return;
    }

    if (cycle > 340) {
      cycle = 0;
      scanline++;

      _pixelBase = scanline * frameBuffer.width;
      _scanlinePhase = _phaseForScanline();

      if (scanline > _preRenderScanline) {
        scanline = 0;
        frames++;

        _pixelBase = 0;
        _scanlinePhase = _phaseForScanline();
      }
    }
  }

  @pragma('vm:prefer-inline')
  void _loadShiftRegisters() {
    // Slide the window by the number of shifts since it was last
    // rebuilt, then decode the newly fetched latches into the
    // next-tile slots.
    final slide = _bgWindowPos;

    for (var i = 0; i < 8; i++) {
      final from = i + slide;

      _bgWindow[i] = from < 16 ? _bgWindow[from] : 0;
    }

    final low = patternTableLowLatch;
    final high = patternTableHighLatch;

    if (bgFourBpp) {
      final low2 = patternTableLow2Latch;
      final high2 = patternTableHigh2Latch;
      final attrBits = bgExtension ? 0 : attributeTableLatch << 5;

      for (var i = 0; i < 8; i++) {
        final shift = 7 - i;
        final pattern =
            ((high2 >> shift) & 0x1) << 3 |
            ((low2 >> shift) & 0x1) << 2 |
            ((high >> shift) & 0x1) << 1 |
            ((low >> shift) & 0x1);

        _bgWindow[8 + i] = pattern == 0 ? 0 : attrBits | pattern;
      }
    } else {
      final attrBits = bgExtension ? 0 : attributeTableLatch << 2;

      for (var i = 0; i < 8; i++) {
        final shift = 7 - i;
        final pattern = ((high >> shift) & 0x1) << 1 | ((low >> shift) & 0x1);

        _bgWindow[8 + i] = pattern == 0 ? 0 : attrBits | pattern;
      }
    }

    _bgWindowPos = 0;

    attribute = attributeTableLatch;
  }

  Uint8List _normalizedWindow() {
    final window = Uint8List(16);

    for (var i = 0; i < 16; i++) {
      final from = i + _bgWindowPos;

      window[i] = from < 16 ? _bgWindow[from] : 0;
    }

    return window;
  }

  void _rebuildWindowFromShiftRegisters(
    int patternHigh,
    int patternLow,
    int attributeHigh,
    int attributeLow,
    int attributeLatchValue,
  ) {
    for (var i = 0; i < 16; i++) {
      final shift = 15 - i;
      final pattern =
          ((patternHigh >> shift) & 0x1) << 1 | ((patternLow >> shift) & 0x1);

      int attrBits;

      if (i < 8) {
        final attrShift = 7 - i;

        attrBits = bgExtension
            ? 0
            : (((attributeHigh >> attrShift) & 0x1) << 3) |
                  (((attributeLow >> attrShift) & 0x1) << 2);
      } else {
        attrBits = bgExtension ? 0 : (attributeLatchValue & 0x3) << 2;
      }

      _bgWindow[i] = pattern == 0 ? 0 : attrBits | pattern;
    }

    _bgWindowPos = 0;
  }

  @pragma('vm:prefer-inline')
  void _renderPixel() {
    final color = _getPixelColor();

    // Use precomputed final RGB color for this palette index (with mirroring)
    final rgb = _paletteLut[color & 0x7f];

    frameBuffer.setPixelWithBase(_pixelBase, currentX, rgb);
  }

  @pragma('vm:prefer-inline')
  int _getPixelColor() {
    if (!_showBackground && !_showSprites) {
      return 0;
    }

    final backgroundColor = _getBackgroundPixelColor();

    if (!_showSprites) {
      return backgroundColor;
    }

    final spriteColor = _getSpritePixelColor(backgroundColor);

    // if the sprite color is selected, bit 4 is set
    final spriteColorValue = spriteColor | 0x10;

    if (!_showBackground) {
      return spriteColorValue;
    }

    if (backgroundColor == 0) {
      return spriteColorValue;
    }

    if (spriteColor == 0) {
      return backgroundColor;
    }

    final spritePriority = spriteColor & 0x10;

    if (spritePriority > 0) {
      return backgroundColor;
    }

    return spriteColorValue;
  }

  @pragma('vm:prefer-inline')
  int _getBackgroundPixelColor() {
    if (!_showBackground) {
      return 0;
    }

    if (!_showLeftBackground && currentX < 8) {
      return 0;
    }

    final slot = _bgWindowPos + x;

    // Beyond the window the hardware registers have shifted in zeros;
    // only reachable when rendering was disabled and re-enabled
    // between reload dots.
    return slot < 16 ? _bgWindow[slot] : 0;
  }

  @pragma('vm:prefer-inline')
  int _getSpritePixelColor(int backgroundColor) {
    if (!_showLeftSprites && currentX < 8) {
      return 0;
    }

    final entry = _spriteLine[currentX];

    if (entry == 0) {
      return 0;
    }

    // sprite 0 hit detection
    if (sprite0OnCurrentLine &&
        entry & 0x80 != 0 &&
        currentX < 255 &&
        backgroundColor != 0) {
      PPUSTATUS_S = 1;
    }

    return entry & 0x7f;
  }

  @pragma('vm:prefer-inline')
  void _shiftRegisters() {
    _bgWindowPos++;
  }

  @pragma('vm:prefer-inline')
  void _fetchNametable() {
    nametableLatch = readPpuMemory(_nametableAddress());
  }

  @pragma('vm:prefer-inline')
  int _nametableAddress() => 0x2000 | ((v >> 10) & 0x3) << 10 | (v & 0x3ff);

  @pragma('vm:prefer-inline')
  void _fetchAttributeTable() {
    // Cache getter values locally to avoid repeated computation
    final coarseX = v & 0x1F;
    final coarseY = (v >> 5) & 0x1F;
    final nametable = (v >> 10) & 0x3;

    final address =
        0x23c0 |
        (nametable << 10) |
        ((coarseY & 0x1C) << 1) |
        ((coarseX & 0x1C) >> 2);

    final value = readPpuMemory(address);

    // attribute table byte layout: DDCCBBAA
    // quadrants A, B, C, D = Top Left, Top Right, Bottom Left, Bottom Right
    // each quadrant covers 2x2 tiles
    // => we select the quadrant using bit 2 of the tile x and y coordinates

    // result is 0, 2, 4, or 6
    // this is the location of the low bit of the quadrant in the fetched byte
    final quadrantShift = ((coarseY & 0x2) << 1) | (coarseX & 0x2);

    attributeTableLatch = (value >> quadrantShift) & 0x03;
  }

  @pragma('vm:prefer-inline')
  int _attributeAddress() {
    final address =
        0x23c0 |
        (v_nametable << 10) |
        ((v_coarseY & 0x1C) << 1) | // we select the attribute table
        ((v_coarseX & 0x1C) >> 2); // using bits 2..4 of the tile x and y

    return address;
  }

  @pragma('vm:prefer-inline')
  int _fourBppAddress(int address, int planeHi) => wideVideoBus
      ? fourBppWideAddress(address, planeHi)
      : fourBppPlanarAddress(address, planeHi);

  @pragma('vm:prefer-inline')
  void _fetchPatternTableLow() {
    final fineY = (v >> 12) & 0x7;
    final address = _bgPatternBase | (nametableLatch << 4) | fineY;

    if (bgExtension) {
      _updateBusAddress(address);

      final eva = attributeTableLatch | (bgEvaBit2 << 2);

      if (bgFourBpp) {
        patternTableLowLatch = readEva4bpp(eva, _fourBppAddress(address, 0));
        patternTableLow2Latch = readEva4bpp(eva, _fourBppAddress(address, 1));
      } else {
        patternTableLowLatch = readEva2bpp(eva, address);
      }

      return;
    }

    if (bgFourBpp) {
      _updateBusAddress(address);

      patternTableLowLatch = readFourBpp(_fourBppAddress(address, 0));
      patternTableLow2Latch = readFourBpp(_fourBppAddress(address, 1));

      return;
    }

    patternTableLowLatch = readPpuMemory(address);
  }

  @pragma('vm:prefer-inline')
  void _fetchPatternTableHigh() {
    final fineY = (v >> 12) & 0x7;
    final address = _bgPatternBase | (nametableLatch << 4) | (fineY + 8);

    if (bgExtension) {
      _updateBusAddress(address);

      final eva = attributeTableLatch | (bgEvaBit2 << 2);

      if (bgFourBpp) {
        patternTableHighLatch = readEva4bpp(eva, _fourBppAddress(address, 0));
        patternTableHigh2Latch = readEva4bpp(eva, _fourBppAddress(address, 1));
      } else {
        patternTableHighLatch = readEva2bpp(eva, address);
      }

      return;
    }

    if (bgFourBpp) {
      _updateBusAddress(address);

      patternTableHighLatch = readFourBpp(_fourBppAddress(address, 0));
      patternTableHigh2Latch = readFourBpp(_fourBppAddress(address, 1));

      return;
    }

    patternTableHighLatch = readPpuMemory(address);
  }

  @pragma('vm:prefer-inline')
  void _incrementX() {
    if (v_coarseX == 31) {
      v_coarseX = 0;
      v_nametableX = 1 - v_nametableX;
    } else {
      v_coarseX++;
    }
  }

  @pragma('vm:prefer-inline')
  void _incrementY() {
    if (v_fineY < 7) {
      v_fineY++;

      return;
    }

    v_fineY = 0;

    if (v_coarseY == 29) {
      v_coarseY = 0;
      v_nametableY = 1 - v_nametableY;
    } else if (v_coarseY == 31) {
      v_coarseY = 0;
    } else {
      v_coarseY++;
    }
  }

  @pragma('vm:prefer-inline')
  void _copyHorizontalBits() {
    v_coarseX = t_coarseX;
    v_nametableX = t_nametableX;
  }

  @pragma('vm:prefer-inline')
  void _copyVerticalBits() {
    v_coarseY = t_coarseY;
    v_fineY = t_fineY;
    v_nametableY = t_nametableY;
  }

  @pragma('vm:prefer-inline')
  void _evaluateSprites() {
    // Cycle ranges: 1-64 clear, 65-256 evaluate, 257-320 fetch, 321
    // rasterize, 328 flag
    if (cycle <= 64) {
      if (cycle >= 1) {
        _clearSecondaryOam();
      }
    } else if (cycle <= 256) {
      _evaluateSpriteRange();
    } else if (cycle <= 320) {
      _fetchSprites();
    } else if (cycle == 321) {
      _rasterizeSpriteLine();
    } else if (cycle == 328) {
      sprite0OnCurrentLine = sprite0OnNextLine;
      sprite0OnNextLine = false;
    }
  }

  @pragma('vm:prefer-inline')
  void _clearSecondaryOam() {
    // Cycles 1-64: Clear secondary OAM on odd cycles
    if (cycle.isOdd) {
      secondaryOam[currentX >> 1] = 0xff;
    }
  }

  @pragma('vm:prefer-inline')
  void _evaluateSpriteRange() {
    // Cycles 65-256: Sprite evaluation
    if (cycle == 65) {
      oamAddress = OAMADDR;
      secondarySpriteCount = 0;
      oamBuffer = 0;
      _resetSpriteEvaluationRange();
    }

    if (cycle.isOdd) {
      oamBuffer = oam[oamAddress & 0xff];

      return;
    }

    if (oamAddress > 252) {
      return;
    }

    final spriteY = oamBuffer;
    final inRange = _spriteVisibleOnScanline(spriteY);

    if (secondarySpriteCount < 8) {
      if (inRange) {
        if (oamAddress == 0) {
          sprite0OnNextLine = true;
        }

        final srcBase = oamAddress & 0xff;
        final tile = oam[srcBase + 1];
        final attribute = oam[srcBase + 2];
        final x = oam[srcBase + 3];
        final packed = spriteY | (tile << 8) | (attribute << 16) | (x << 24);

        _secondaryOamWords[secondarySpriteCount] = packed;

        secondarySpriteCount++;
      }

      oamAddress += 4;

      return;
    }

    if (inRange) {
      PPUSTATUS_O = 1;
      oamAddress += 4;
    } else {
      oamAddress += 5;
    }
  }

  @pragma('vm:prefer-inline')
  void _fetchSprites() {
    // Cycles 257-320: Sprite fetch
    if (cycle == 257) {
      spriteCount = secondarySpriteCount;
    }

    final subcycle = cycle - 257;
    final sprite = subcycle >> 3;
    final offset = subcycle & 0x7;
    final spriteWord = _secondaryOamWords[sprite];

    switch (offset) {
      case 0:
        readPpuMemory(_nametableAddress());
      case 2:
        readPpuMemory(_attributeAddress());

        _spriteOutputs[sprite].attribute = (spriteWord >> 16) & 0xff;
      case 3:
        _spriteOutputs[sprite].x = spriteWord >> 24;
      case 4:
        _loadSprite(sprite);
    }
  }

  @pragma('vm:prefer-inline')
  void _fetchSpritesForBusOnly() {
    final subcycle = cycle - 257;

    switch (subcycle & 0x7) {
      case 0:
        readPpuMemory(_nametableAddress());
      case 2:
        readPpuMemory(_attributeAddress());
      case 4:
        final spriteWord = _secondaryOamWords[subcycle >> 3];
        final tileIndex = (spriteWord >> 8) & 0xff;
        final patternTable = PPUCTRL_H == 1 ? tileIndex & 1 : PPUCTRL_S;
        final address = ((patternTable & 1) << 12) | (tileIndex << 4);

        readPpuMemory(address);
        readPpuMemory(address | 8);
    }
  }

  void _rasterizeSpriteLine() {
    _spriteLine.fillRange(0, 256, 0);

    final fourBpp = spriteFourBpp;

    for (var i = spriteCount - 1; i >= 0; i--) {
      final spriteOutput = _spriteOutputs[i];
      final attribute = spriteOutput.attribute;
      final flipH = (attribute >> 6) & 1;
      final priorityBit = ((attribute >> 5) & 1) << 4;
      final attrBits = fourBpp
          ? (attribute & 0x3) << 5
          : (attribute & 0x3) << 2;
      final base = priorityBit | attrBits;
      final sprite0Bit = i == 0 ? 0x80 : 0;
      final patternLow = spriteOutput.patternLow;
      final patternHigh = spriteOutput.patternHigh;
      final patternLow2 = spriteOutput.patternLow2;
      final patternHigh2 = spriteOutput.patternHigh2;

      for (var xOffset = 0; xOffset < 8; xOffset++) {
        final x = spriteOutput.x + xOffset;

        if (x > 255) {
          break;
        }

        final fineX = flipH == 1 ? xOffset : 7 - xOffset;
        var pattern =
            (((patternHigh >> fineX) & 1) << 1) | (patternLow >> fineX) & 1;

        if (fourBpp) {
          pattern |=
              (((patternHigh2 >> fineX) & 1) << 3) |
              (((patternLow2 >> fineX) & 1) << 2);
        }

        if (pattern == 0) {
          continue;
        }

        _spriteLine[x] = base | pattern | sprite0Bit;
      }
    }
  }

  void _resetSpriteEvaluationRange() {
    final spriteHeight = PPUCTRL_H == 0 ? 8 : 16;

    _spriteRangeMinY = scanline - spriteHeight + 1;
  }

  bool _spriteVisibleOnScanline(int spriteY) {
    return spriteY <= scanline && spriteY >= _spriteRangeMinY;
  }

  void _loadSprite(int sprite) {
    final bigSprites = PPUCTRL_H == 1;
    final spriteWord = _secondaryOamWords[sprite];
    final tileIndex = (spriteWord >> 8) & 0xff;
    final attribute = _spriteOutputs[sprite].attribute;
    final flipV = (attribute >> 7) > 0;

    final y = spriteWord & 0xff;
    final yOffset = scanline - y;
    final fineY = flipV ? (bigSprites ? 15 : 7) - yOffset : yOffset;

    final isBigSpriteSecondTile = yOffset < 8;
    final bigSpriteOffset = isBigSpriteSecondTile == flipV ? 1 : 0;
    final tile = bigSprites
        ? ((tileIndex & 0xfe) + bigSpriteOffset)
        : tileIndex;

    final patternTable = bigSprites ? (tileIndex & 1) : PPUCTRL_S;

    final addressOffset = bigSprites && !isBigSpriteSecondTile ? 8 : 0;

    final base = (patternTable & 1) << 12;

    final lowAddress = base | (tile << 4) | (fineY + addressOffset);
    final highAddress = base | (tile << 4) | (fineY + 8 - addressOffset);

    final output = _spriteOutputs[sprite];

    if (spriteExtension) {
      final eva = (attribute >> 2) & 0x7;

      _updateBusAddress(lowAddress);

      if (spriteFourBpp) {
        output.patternLow = readEva4bpp(eva, _fourBppAddress(lowAddress, 0));
        output.patternLow2 = readEva4bpp(eva, _fourBppAddress(lowAddress, 1));
      } else {
        output.patternLow = readEva2bpp(eva, lowAddress);
      }

      _updateBusAddress(highAddress);

      if (spriteFourBpp) {
        output.patternHigh = readEva4bpp(eva, _fourBppAddress(highAddress, 0));
        output.patternHigh2 = readEva4bpp(eva, _fourBppAddress(highAddress, 1));
      } else {
        output.patternHigh = readEva2bpp(eva, highAddress);
      }

      return;
    }

    if (spriteFourBpp) {
      _updateBusAddress(lowAddress);

      output.patternLow = readFourBpp(_fourBppAddress(lowAddress, 0));
      output.patternLow2 = readFourBpp(_fourBppAddress(lowAddress, 1));

      _updateBusAddress(highAddress);

      output.patternHigh = readFourBpp(_fourBppAddress(highAddress, 0));
      output.patternHigh2 = readFourBpp(_fourBppAddress(highAddress, 1));

      return;
    }

    output.patternLow = readPpuMemory(lowAddress);
    output.patternHigh = readPpuMemory(highAddress);
  }

  void _rebuildPaletteLut() {
    _emphasisBase = _emphasisRow() << 6;

    final limit = extendedPalette ? 0x80 : 0x20;

    for (var i = 0; i < limit; i++) {
      final remapped = _remapPaletteIndex(i);
      final value = _computePaletteEntry(remapped);

      _setPaletteEntry(remapped, value);
    }
  }

  int _emphasisRow() {
    final r = PPUMASK_ER;
    final g = PPUMASK_EG;
    final b = PPUMASK_EB;

    return _region == Region.pal
        ? g | (r << 1) | (b << 2)
        : r | (g << 1) | (b << 2);
  }

  void onPaletteWrite(int index) {
    final limit = extendedPalette ? 0x80 : 0x20;

    if (index < 0 || index >= limit) {
      return;
    }

    final rem = _remapPaletteIndex(index);
    final val = _computePaletteEntry(rem);

    _setPaletteEntry(rem, val);
  }

  void _setPaletteEntry(int index, int value) {
    if (extendedPalette) {
      _paletteLut[index] = value;

      switch (index) {
        case 0x00:
          _paletteLut[0x10] = value;
        case 0x04:
          _paletteLut[0x14] = value;
        case 0x08:
          _paletteLut[0x18] = value;
        case 0x0c:
          _paletteLut[0x1c] = value;
      }

      return;
    }

    switch (index) {
      case 0x00:
        _paletteLut[0x00] = value;
        _paletteLut[0x10] = value;
      case 0x04:
        _paletteLut[0x04] = value;
        _paletteLut[0x14] = value;
      case 0x08:
        _paletteLut[0x08] = value;
        _paletteLut[0x18] = value;
      case 0x0c:
        _paletteLut[0x0c] = value;
        _paletteLut[0x1c] = value;
      default:
        _paletteLut[index] = value;
    }
  }

  int _computePaletteEntry(int index) {
    final greyMask = PPUMASK_Gr == 1 ? 0x30 : 0x3f;

    return _systemPalette[_emphasisBase | (palette[index & 0x7f] & greyMask)];
  }

  int _remapPaletteIndex(int index) {
    if (extendedPalette) {
      return switch (index & 0xff) {
        0x10 => 0x00,
        0x14 => 0x04,
        0x18 => 0x08,
        0x1c => 0x0c,
        _ => index & 0xff,
      };
    }

    return switch (index & 0x1f) {
      0x10 => 0x00,
      0x14 => 0x04,
      0x18 => 0x08,
      0x1c => 0x0c,
      _ => index & 0x1f,
    };
  }

  void updatePpuMapping(int block, Uint8List? source) {
    if (block < 0 || block >= _ppuBlocks.length) {
      return;
    }

    _ppuBlocks[block] = source;
  }

  void updateFourBppMapping(int block, Uint8List? source) {
    if (block < 0 || block >= _fourBppBlocks.length) {
      return;
    }

    _fourBppBlocks[block] = source;
  }

  @pragma('vm:prefer-inline')
  int readFourBpp(int address) {
    final source = _fourBppBlocks[(address >> _ppuBlockAddressWidth) & 0xf];

    if (source == null) {
      return 0;
    }

    return source[address & _ppuBlockMask];
  }

  void updateEva2bppMapping(int index, Uint8List? source) {
    if (index < 0 || index >= _evaBlocks2bpp.length) {
      return;
    }

    _evaBlocks2bpp[index] = source;
  }

  void updateEva4bppMapping(int index, Uint8List? source) {
    if (index < 0 || index >= _evaBlocks4bpp.length) {
      return;
    }

    _evaBlocks4bpp[index] = source;
  }

  @pragma('vm:prefer-inline')
  int readEva2bpp(int eva, int address) {
    final source =
        _evaBlocks2bpp[(eva << 3) | ((address >> _ppuBlockAddressWidth) & 0x7)];

    if (source == null) {
      return 0;
    }

    return source[address & _ppuBlockMask];
  }

  @pragma('vm:prefer-inline')
  int readEva4bpp(int eva, int address) {
    final source =
        _evaBlocks4bpp[(eva << 4) | ((address >> _ppuBlockAddressWidth) & 0xf)];

    if (source == null) {
      return 0;
    }

    return source[address & _ppuBlockMask];
  }
}
