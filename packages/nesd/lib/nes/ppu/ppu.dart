// register names don't follow dart naming conventions
// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/ppu/frame_buffer.dart';
import 'package:nesd/nes/ppu/ppu_state.dart';
import 'package:nesd/nes/ppu/sprite_output.dart';
import 'package:nesd/nes/region.dart';

const systemPalette = [
  0x626262,
  0x001fb2,
  0x2404c8,
  0x5200b2,
  0x730076,
  0x800024,
  0x730b00,
  0x522800,
  0x244400,
  0x005700,
  0x005c00,
  0x005324,
  0x003c76,
  0x000000,
  0x000000,
  0x000000,
  0xababab,
  0x0d57ff,
  0x4b30ff,
  0x8a13ff,
  0xbc08d6,
  0xd21269,
  0xc72e00,
  0x9d5400,
  0x607b00,
  0x209800,
  0x00a300,
  0x009942,
  0x007db4,
  0x000000,
  0x000000,
  0x000000,
  0xffffff,
  0x53aeff,
  0x9085ff,
  0xd365ff,
  0xff57ff,
  0xff5dcf,
  0xff7757,
  0xfa9e00,
  0xbdc700,
  0x7ae700,
  0x43f611,
  0x26ef7e,
  0x2cd5f6,
  0x4e4e4e,
  0x000000,
  0x000000,
  0xffffff,
  0xb6e1ff,
  0xced1ff,
  0xe9c3ff,
  0xffbcff,
  0xffbdf4,
  0xffc6c3,
  0xffd59a,
  0xe9e681,
  0xcef481,
  0xb6fb9a,
  0xa9fac3,
  0xa9f0f4,
  0xb8b8b8,
  0x000000,
  0x000000,
];

const ntscConsoleCyclesPerCycle = 4;
const palConsoleCyclesPerCycle = 5;

const ntscPreRenderScanline = 261;
const palPreRenderScanline = 311;

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
  final Uint8List palette = Uint8List(0x20);
  // Precomputed final RGB colors per palette entry
  // (greyscale + emphasis already applied)
  final Uint32List _paletteLut = Uint32List(0x20);

  final FrameBuffer frameBuffer = FrameBuffer(width: 256, height: 240);
  final List<Uint8List?> _ppuBlocks = List<Uint8List?>.filled(
    _ppuBlockCount,
    null,
  );

  bool _showBackground = false;
  bool _showSprites = false;
  bool _showLeftBackground = false;
  bool _showLeftSprites = false;
  bool _nmiEnabled = false;

  int _consoleCyclesPerCycle = ntscConsoleCyclesPerCycle;
  int consoleCycles = 0;
  int cycles = 0;
  int cycle = 0;
  int scanline = 0;
  int frames = 0;

  int _preRenderScanline = ntscPreRenderScanline;

  int _pixelBase = 0;

  int nametableLatch = 0;

  int patternTableHighLatch = 0;
  int patternTableLowLatch = 0;

  int patternTableHighShift = 0;
  int patternTableLowShift = 0;

  int attributeTableLatch = 0;

  int attributeTableHighShift = 0;
  int attributeTableLowShift = 0;

  int attribute = 0;

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
    patternTableHighShift: patternTableHighShift,
    patternTableLowShift: patternTableLowShift,
    attributeTableLatch: attributeTableLatch,
    attributeTableHighShift: attributeTableHighShift,
    attributeTableLowShift: attributeTableLowShift,
    attribute: attribute,
    oamAddress: oamAddress,
    oamBuffer: oamBuffer,
    spriteCount: spriteCount,
    secondarySpriteCount: secondarySpriteCount,
    sprite0OnNextLine: sprite0OnNextLine,
    sprite0OnCurrentLine: sprite0OnCurrentLine,
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
    frameBuffer.setPixels(state.frameBuffer.pixels);
    consoleCycles = state.consoleCycles;
    cycles = state.cycles;
    cycle = state.cycle;
    scanline = state.scanline;
    frames = state.frames;
    _pixelBase = scanline * frameBuffer.width;
    nametableLatch = state.nametableLatch;
    patternTableHighLatch = state.patternTableHighLatch;
    patternTableLowLatch = state.patternTableLowLatch;
    patternTableHighShift = state.patternTableHighShift;
    patternTableLowShift = state.patternTableLowShift;
    attributeTableLatch = state.attributeTableLatch;
    attributeTableHighShift = state.attributeTableHighShift;
    attributeTableLowShift = state.attributeTableLowShift;
    attribute = state.attribute;
    oamAddress = state.oamAddress;
    oamBuffer = state.oamBuffer;
    spriteCount = state.spriteCount;
    secondarySpriteCount = state.secondarySpriteCount;
    sprite0OnNextLine = state.sprite0OnNextLine;
    sprite0OnCurrentLine = state.sprite0OnCurrentLine;

    for (var i = 0; i < _spriteOutputs.length; i++) {
      _spriteOutputs[i].state = state.spriteOutputs[i];
    }

    _nmiEnabled = (PPUCTRL & 0x80) != 0;
    _bgPatternBase = (PPUCTRL_B & 1) << 12;
    _updateMaskFlags();

    _rebuildPaletteLut();
  }

  // we don't need a getter from this
  // ignore: avoid_setters_without_getters
  set region(Region region) {
    switch (region) {
      case Region.ntsc:
        _consoleCyclesPerCycle = ntscConsoleCyclesPerCycle;
        _preRenderScanline = ntscPreRenderScanline;
      case Region.pal:
        _consoleCyclesPerCycle = palConsoleCyclesPerCycle;
        _preRenderScanline = palPreRenderScanline;
    }
  }

  void reset() {
    consoleCycles = 0;
    cycles = 0;
    cycle = 0;
    scanline = 0;
    frames = 0;

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
    patternTableHighShift = 0;
    patternTableLowShift = 0;
    attributeTableLatch = 0;
    attributeTableHighShift = 0;
    attributeTableLowShift = 0;
    attribute = 0;

    oamAddress = 0;
    oamBuffer = 0;

    spriteCount = 0;
    secondarySpriteCount = 0;

    sprite0OnNextLine = false;
    sprite0OnCurrentLine = false;

    ram.fillRange(0, ram.length, 0);
    oam.fillRange(0, oam.length, 0);
    secondaryOam.fillRange(0, secondaryOam.length, 0);
    palette.fillRange(0, palette.length, 0);
    _ppuBlocks.fillRange(0, _ppuBlocks.length, null);

    _pixelBase = 0;

    _nmiEnabled = false;
    _bgPatternBase = 0;
    _updateMaskFlags();

    frameBuffer.resetBuffers();

    _rebuildPaletteLut();
  }

  int getPixelBrightness(int x, int y) {
    if (!_showBackground && !_showSprites) {
      return 0;
    }

    return frameBuffer.getPixelBrightness(x, y);
  }

  @pragma('vm:prefer-inline')
  int readPpuMemory(int address, {bool updateBusAddress = true}) {
    if (updateBusAddress) {
      _updateBusAddress(address);
    }

    final maskedAddress = address & 0x3fff;

    if (maskedAddress < 0x3f00) {
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

  void _updateBusAddress(int address) =>
      bus.cartridge.mapper.updatePpuAddress(address);

  int readRegister(int address, {bool disableSideEffects = false}) {
    return switch (address) {
      0x2002 => _readPPUSTATUS(disableSideEffects: disableSideEffects),
      0x2004 => _readOAMDATA(),
      0x2007 => _readPPUDATA(disableSideEffects: disableSideEffects),
      _ => 0,
    };
  }

  void writeRegister(int address, int value) {
    final wrapped = address & 0x7;

    switch (wrapped) {
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
    while (consoleCycles < targetCycles) {
      step();
    }
  }

  void step() {
    if (scanline < 240) {
      _stepVisibleScanline();
    } else if (scanline == _preRenderScanline) {
      _stepPreRenderScanline();
    } else if (scanline == 241) {
      _stepVblankLine();
    }
    // Idle scanlines 242-260: just update counters

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

    // OAMADDR = 0 at cycles 257-320 (regardless of rendering)
    if (cycle >= 257 && cycle <= 320) {
      OAMADDR = 0x0000;
    }

    // Nametable reads at cycles 337, 339 (regardless of rendering)
    if (cycle == 337 || cycle == 339) {
      readPpuMemory(_nametableAddress());
    }

    // Cycle 0 bus address update
    if (cycle == 0 && renderingActive && (scanline > 0 || (frames & 1) == 0)) {
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
    }

    // OAMADDR = 0 at cycles 257-320 (regardless of rendering)
    if (cycle >= 257 && cycle <= 320) {
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

      bus.clearNmi();
    }
  }

  @pragma('vm:prefer-inline')
  void _stepVblankLine() {
    // Set vblank flag and trigger NMI at cycle 1
    if (cycle == 1) {
      PPUSTATUS_V = 1;

      spriteCount = 0;
      secondarySpriteCount = 0;

      if (_nmiEnabled) {
        bus.triggerNmi();
      }
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

    if (!disableSideEffects) {
      PPUSTATUS_V = 0;
      w = 0;

      bus.clearNmi();
    }

    return value;
  }

  int _readOAMDATA() {
    return oam[OAMADDR];
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

    if (!disableSideEffects) {
      v += PPUCTRL_I == 0 ? 1 : 32;
    }

    return value;
  }

  void _writePPUCTRL(int value) {
    PPUCTRL = value;

    _nmiEnabled = (value & 0x80) != 0;

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
    // ignore writes while rendering
    if (scanline < 240 && cycle >= 1 && cycle <= 256) {
      return;
    }

    oam[OAMADDR] = value;

    OAMADDR++;
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
  }

  @pragma('vm:prefer-inline')
  void _updateCounters() {
    consoleCycles += _consoleCyclesPerCycle;
    cycles++;
    cycle++;

    if (scanline == _preRenderScanline && cycle == 340 && frames.isOdd) {
      scanline = 0;
      cycle = 0;
      frames++;

      _pixelBase = 0;

      return;
    }

    if (cycle > 340) {
      cycle = 0;
      scanline++;

      _pixelBase = scanline * frameBuffer.width;

      if (scanline > _preRenderScanline) {
        scanline = 0;
        frames++;

        _pixelBase = 0;
      }
    }
  }

  @pragma('vm:prefer-inline')
  void _loadShiftRegisters() {
    patternTableHighShift &= ~0xFF;
    patternTableHighShift |= patternTableHighLatch;

    patternTableLowShift &= ~0xFF;
    patternTableLowShift |= patternTableLowLatch;

    attribute = attributeTableLatch;
  }

  @pragma('vm:prefer-inline')
  void _renderPixel() {
    final color = _getPixelColor();

    // Use precomputed final RGB color for this palette index (with mirroring)
    final rgb = _paletteLut[color & 0x1f];

    frameBuffer.setPixelWithBase(_pixelBase, currentX, rgb);
  }

  int _applyEmphasis(int color) {
    final red = color & 0xff;
    final green = (color >> 8) & 0xff;
    final blue = (color >> 16) & 0xff;

    // TODO implement an accurate algorithm
    final resultRed = (PPUMASK_EG == 1 || PPUMASK_EB == 1) ? (red >> 2) : red;
    final resultGreen = (PPUMASK_ER == 1 || PPUMASK_EB == 1)
        ? (green >> 2)
        : green;
    final resultBlue = (PPUMASK_ER == 1 || PPUMASK_EG == 1)
        ? (blue >> 2)
        : blue;

    return (resultBlue << 16) | (resultGreen << 8) | resultRed;
  }

  int _packPaletteColor(int color) {
    final red = (color >> 16) & 0xff;
    final green = (color >> 8) & 0xff;
    final blue = color & 0xff;

    return 0xff000000 | (blue << 16) | (green << 8) | red;
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

    final patternShift = 15 - x;

    final patternHigh = (patternTableHighShift >> patternShift) & 0x1;
    final patternLow = (patternTableLowShift >> patternShift) & 0x1;

    final pattern = patternHigh << 1 | patternLow;

    if (pattern == 0) {
      return 0;
    }

    final attributeShift = 7 - x;

    final paletteIndexHigh = (attributeTableHighShift >> attributeShift) & 0x1;
    final paletteIndexLow = (attributeTableLowShift >> attributeShift) & 0x1;

    return paletteIndexHigh << 3 | paletteIndexLow << 2 | pattern;
  }

  @pragma('vm:prefer-inline')
  int _getSpritePixelColor(int backgroundColor) {
    if (!_showLeftSprites && currentX < 8) {
      return 0;
    }

    for (var sprite = 0; sprite < spriteCount; sprite++) {
      final spriteOutput = _spriteOutputs[sprite];
      final xOffset = currentX - spriteOutput.x;

      if (xOffset < 0 || xOffset > 7) {
        continue;
      }

      final attribute = spriteOutput.attribute;
      final flipH = (attribute >> 6) & 1;

      final fineX = flipH == 1 ? xOffset : 7 - xOffset;

      final patternLow = spriteOutput.patternLow;
      final patternHigh = spriteOutput.patternHigh;
      final pattern =
          (((patternHigh >> fineX) & 1) << 1) | (patternLow >> fineX) & 1;

      if (pattern == 0) {
        continue;
      }

      // sprite 0 hit detection
      if (sprite0OnCurrentLine &&
          sprite == 0 &&
          currentX < 255 &&
          backgroundColor & 0x3 != 0 &&
          pattern != 0) {
        PPUSTATUS_S = 1;
      }

      final priority = (attribute >> 5) & 1;
      final palette = attribute & 0x3;

      return priority << 4 | palette << 2 | pattern;
    }

    return 0;
  }

  @pragma('vm:prefer-inline')
  void _shiftRegisters() {
    patternTableHighShift <<= 1;
    patternTableLowShift <<= 1;

    attributeTableHighShift <<= 1;
    attributeTableLowShift <<= 1;

    attributeTableHighShift |= (attribute >> 1) & 1;
    attributeTableLowShift |= attribute & 1;
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
  void _fetchPatternTableLow() {
    final fineY = (v >> 12) & 0x7;
    final address = _bgPatternBase | (nametableLatch << 4) | fineY;

    patternTableLowLatch = readPpuMemory(address);
  }

  @pragma('vm:prefer-inline')
  void _fetchPatternTableHigh() {
    final fineY = (v >> 12) & 0x7;
    final address = _bgPatternBase | (nametableLatch << 4) | (fineY + 8);

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

  void _evaluateSprites() {
    if (cycle >= 1 && cycle <= 64) {
      if (cycle.isOdd) {
        secondaryOam[currentX >> 1] = 0xff;
      }

      return;
    }

    if (cycle >= 65 && cycle <= 256) {
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

      return;
    }

    if (cycle >= 257 && cycle <= 320) {
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

      return;
    }

    if (cycle == 328) {
      sprite0OnCurrentLine = sprite0OnNextLine;
      sprite0OnNextLine = false;
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

    _spriteOutputs[sprite].patternLow = readPpuMemory(lowAddress);
    _spriteOutputs[sprite].patternHigh = readPpuMemory(highAddress);
  }

  // Called when PPUMASK changes or palette memory is written to, to update LUT.
  void _rebuildPaletteLut() {
    for (var i = 0; i < 0x20; i++) {
      final remapped = _remapPaletteIndex(i);
      final value = _computePaletteEntry(remapped);

      _setPaletteEntry(remapped, value);
    }
  }

  void onPaletteWrite(int index) {
    if (index < 0 || index >= 0x20) {
      return;
    }

    final rem = _remapPaletteIndex(index);
    final val = _computePaletteEntry(rem);

    _setPaletteEntry(rem, val);
  }

  void _setPaletteEntry(int index, int value) {
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
    final idx = index & 0x1f;
    final greyMask = PPUMASK_Gr == 1 ? 0x30 : 0x3f;
    final palVal = palette[idx] & greyMask;
    final rgb = systemPalette[palVal];

    final emphasized = _applyEmphasis(rgb);

    return _packPaletteColor(emphasized);
  }

  int _remapPaletteIndex(int index) {
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
}
