// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

import 'package:nes/extension/bit_extension.dart';
import 'package:nes/nes/bus.dart';
import 'package:nes/nes/ppu/frame_buffer.dart';

const systemPalette = {
  0x00: 0x626262,
  0x01: 0x001fb2,
  0x02: 0x2404c8,
  0x03: 0x5200b2,
  0x04: 0x730076,
  0x05: 0x800024,
  0x06: 0x730b00,
  0x07: 0x522800,
  0x08: 0x244400,
  0x09: 0x005700,
  0x0a: 0x005c00,
  0x0b: 0x005324,
  0x0c: 0x003c76,
  0x0d: 0x000000,
  0x0e: 0x000000,
  0x0f: 0x000000,
  0x10: 0xababab,
  0x11: 0x0d57ff,
  0x12: 0x4b30ff,
  0x13: 0x8a13ff,
  0x14: 0xbc08d6,
  0x15: 0xd21269,
  0x16: 0xc72e00,
  0x17: 0x9d5400,
  0x18: 0x607b00,
  0x19: 0x209800,
  0x1a: 0x00a300,
  0x1b: 0x009942,
  0x1c: 0x007db4,
  0x1d: 0x000000,
  0x1e: 0x000000,
  0x1f: 0x000000,
// 	palette[32] = Color(236, 238, 236);
  0x20: 0xffffff,
// 	palette[33] = Color(76, 154, 236);
  0x21: 0x53aeff,
// 	palette[34] = Color(120, 124, 236);
  0x22: 0x9085ff,
// 	palette[35] = Color(176, 98, 236);
  0x23: 0xd365ff,
// 	palette[36] = Color(228, 84, 236);
  0x24: 0xff57ff,
// 	palette[37] = Color(236, 88, 180);
  0x25: 0xff5dcf,
// 	palette[38] = Color(236, 106, 100);
  0x26: 0xff7757,
// 	palette[39] = Color(212, 136, 32);
  0x27: 0xfa9e00,
// 	palette[40] = Color(160, 170, 0);
  0x28: 0xbdc700,
// 	palette[41] = Color(116, 196, 0);
  0x29: 0x7ae700,
// 	palette[42] = Color(76, 208, 32);
  0x2a: 0x43f611,
// 	palette[43] = Color(56, 204, 108);
  0x2b: 0x26ef7e,
// 	palette[44] = Color(56, 180, 204);
  0x2c: 0x2cd5f6,
// 	palette[45] = Color(60, 60, 60);
  0x2d: 0x4e4e4e,
  0x2e: 0x000000,
  0x2f: 0x000000,
// 	palette[48] = Color(236, 238, 236);
  0x30: 0xffffff,
// 	palette[49] = Color(168, 204, 236);
  0x31: 0xb6e1ff,
// 	palette[50] = Color(188, 188, 236);
  0x32: 0xced1ff,
// 	palette[51] = Color(212, 178, 236);
  0x33: 0xe9c3ff,
// 	palette[52] = Color(236, 174, 236);
  0x34: 0xffbcff,
// 	palette[53] = Color(236, 174, 212);
  0x35: 0xffbdf4,
// 	palette[54] = Color(236, 180, 176);
  0x36: 0xffc6c3,
// 	palette[55] = Color(228, 196, 144);
  0x37: 0xffd59a,
// 	palette[56] = Color(204, 210, 120);
  0x38: 0xe9e681,
// 	palette[57] = Color(180, 222, 120);
  0x39: 0xcef481,
// 	palette[58] = Color(168, 226, 144);
  0x3a: 0xb6fb9a,
// 	palette[59] = Color(152, 226, 180);
  0x3b: 0xa9fac3,
// 	palette[60] = Color(160, 214, 228);
  0x3c: 0xa9f0f4,
// 	palette[61] = Color(160, 162, 160);
  0x3d: 0xb8b8b8,
  0x3e: 0x000000,
  0x3f: 0x000000,
};

class PPU {
  PPU(this.bus);

  final Bus bus;

  int PPUCTRL = 0x00;
  int PPUMASK = 0x00;
  int PPUSTATUS = 0x00;
  int OAMADDR = 0x00;
  // TODO bud-30.05.24 increase OAMADDR after write
  int OAMDATA = 0x00;
  int PPUSCROLL = 0x00;
  int PPUADDR = 0x00;
  int PPUDATA = 0x00;
  // TODO bud-30.05.24 write triggers DMA transfer
  int OAMDMA = 0x00;

  // during rendering: scroll position, outside rendering: VRAM address
  int v = 0;
  // during rendering: starting coarse X scroll, starting Y scroll
  // outside rendering: scroll or VRAM address
  int t = 0;
  // fine X scroll
  int x = 0;
  // first or second write toggle
  int w = 0;

  int get v_coarseX => v & 0x1F;
  int get v_coarseY => (v >> 5) & 0x1F;
  int get v_nametable => (v >> 10) & 0x3;
  int get v_nametableX => (v >> 10) & 0x1;
  int get v_nametableY => (v >> 11) & 0x1;
  int get v_fineY => (v >> 12) & 0x7;

  set v_coarseX(int value) => v = (v & 0xFFE0) | (value & 0x1F);
  set v_coarseY(int value) => v = (v & 0xFC1F) | ((value & 0x1F) << 5);
  set v_nametable(int value) => v = (v & 0xF3FF) | ((value & 0x3) << 10);
  set v_nametableX(int value) => v = v.setBit(10, value);
  set v_nametableY(int value) => v = v.setBit(11, value);
  set v_fineY(int value) => v = (v & 0x0FFF) | ((value & 0x7) << 12);

  int get t_coarseX => t & 0x1F;
  int get t_coarseY => (t >> 5) & 0x1F;
  int get t_nametable => (t >> 10) & 0x3;
  int get t_nametableX => (t >> 10) & 0x1;
  int get t_nametableY => (t >> 11) & 0x1;
  int get t_fineY => (t >> 12) & 0x7;

  int get PPUCTRL_N => PPUCTRL & 0x3; // nametable address
  int get PPUCTRL_I => PPUCTRL.bit(2); // VRAM address increment
  int get PPUCTRL_S => PPUCTRL.bit(3); // sprite pattern table address (8x8)
  int get PPUCTRL_B => PPUCTRL.bit(4); // background pattern table address
  int get PPUCTRL_H => PPUCTRL.bit(5); // sprite size
  int get PPUCTRL_P => PPUCTRL.bit(6); // PPU master/slave select
  int get PPUCTRL_V => PPUCTRL.bit(7); // enable vblank NMI

  int get PPUCTRL_X => PPUCTRL.bit(0); // scroll X high bit
  int get PPUCTRL_Y => PPUCTRL.bit(1); // scroll Y high bit

  set PPUCTRL_N(int value) => PPUCTRL |= value & 0x3;
  set PPUCTRL_I(int value) => PPUCTRL = PPUCTRL.setBit(2, value);
  set PPUCTRL_S(int value) => PPUCTRL = PPUCTRL.setBit(3, value);
  set PPUCTRL_B(int value) => PPUCTRL = PPUCTRL.setBit(4, value);
  set PPUCTRL_H(int value) => PPUCTRL = PPUCTRL.setBit(5, value);
  set PPUCTRL_P(int value) => PPUCTRL = PPUCTRL.setBit(6, value);
  set PPUCTRL_V(int value) => PPUCTRL = PPUCTRL.setBit(7, value);

  set PPUCTRL_X(int value) => PPUCTRL = PPUCTRL.setBit(0, value);
  set PPUCTRL_Y(int value) => PPUCTRL = PPUCTRL.setBit(1, value);

  int get PPUMASK_Gr => PPUMASK.bit(0); // greyscale
  int get PPUMASK_m => PPUMASK.bit(1); // show background in leftmost 8 pixels
  int get PPUMASK_M => PPUMASK.bit(2); // show sprites in leftmost 8 pixels
  int get PPUMASK_b => PPUMASK.bit(3); // show background
  int get PPUMASK_s => PPUMASK.bit(4); // show sprites
  int get PPUMASK_R => PPUMASK.bit(5); // emphasize red
  int get PPUMASK_G => PPUMASK.bit(6); // emphasize green
  int get PPUMASK_B => PPUMASK.bit(7); // emphasize blue

  set PPUMASK_Gr(int value) => PPUMASK = PPUMASK.setBit(0, value);
  set PPUMASK_m(int value) => PPUMASK = PPUMASK.setBit(1, value);
  set PPUMASK_M(int value) => PPUMASK = PPUMASK.setBit(2, value);
  set PPUMASK_b(int value) => PPUMASK = PPUMASK.setBit(3, value);
  set PPUMASK_s(int value) => PPUMASK = PPUMASK.setBit(4, value);
  set PPUMASK_R(int value) => PPUMASK = PPUMASK.setBit(5, value);
  set PPUMASK_G(int value) => PPUMASK = PPUMASK.setBit(6, value);
  set PPUMASK_B(int value) => PPUMASK = PPUMASK.setBit(7, value);

  int get PPUSTATUS_O => PPUSTATUS.bit(5); // sprite overflow
  int get PPUSTATUS_S => PPUSTATUS.bit(6); // sprite 0 hit
  int get PPUSTATUS_V => PPUSTATUS.bit(7); // vblank active

  set PPUSTATUS_O(int value) => PPUSTATUS = PPUSTATUS.setBit(5, value);
  set PPUSTATUS_S(int value) => PPUSTATUS = PPUSTATUS.setBit(6, value);
  set PPUSTATUS_V(int value) => PPUSTATUS = PPUSTATUS.setBit(7, value);

  final Uint8List ram = Uint8List(0x0800);
  final Uint8List oam = Uint8List(0x0100);
  final Uint8List secondaryOam = Uint8List(0x20);
  final Uint8List palette = Uint8List(0x20);

  final FrameBuffer frameBuffer = FrameBuffer(width: 256, height: 240);

  int cycle = 0;
  int scanline = 0;
  int frames = 0;

  int nametableLatch = 0;

  int patternTableHighLatch = 0;
  int patternTableLowLatch = 0;

  int patternTableHighShift = 0;
  int patternTableLowShift = 0;

  int attributeTableLatch = 0;

  int attributeTableHighShift = 0;
  int attributeTableLowShift = 0;

  int attribute = 0;

  void reset() {
    cycle = 0;
    scanline = 0;
    frames = 0;
  }

  int read(int address) => bus.ppuRead(address);

  void write(int address, int value) => bus.ppuWrite(address, value);

  int readRegister(int address) {
    return switch (address) {
      0x2002 => _readPPUSTATUS(),
      0x2004 => _readOAMDATA(),
      0x2007 => _readPPUDATA(),
      _ => 0,
    };
  }

  void writeRegister(int address, int value) {
    switch (address) {
      case 0x2000:
        _writePPUCTRL(value);
      case 0x2001:
        PPUMASK = value;
      case 0x2003:
        OAMADDR = value;
      case 0x2004:
        OAMDATA = value;
      case 0x2005:
        _writePPUSCROLL(value);
      case 0x2006:
        _writePPUADDR(value);
      case 0x2007:
        _writePPUDATA(value);
      case 0x4014:
        OAMDMA = value;
    }
  }

  bool get lineVisible => scanline < 240;
  bool get linePreRender => scanline == 261;
  bool get lineFetch => lineVisible || linePreRender;

  bool get cycleVisible => cycle >= 1 && cycle <= 256;
  bool get cyclePreFetch => cycle >= 321 && cycle <= 336;
  bool get cycleFetch => cycleVisible || cyclePreFetch;

  bool get renderingEnabled => PPUMASK_b == 1 || PPUMASK_s == 1;
  bool get rendering => lineVisible && cycleVisible;

  bool get fetching => lineFetch && cycleFetch;

  void step() {
    // rendering

    if (linePreRender || lineVisible) {
      if (cycle >= 257 && cycle <= 320) {
        OAMADDR = 0x0000;
      }
    }

    // visible scanlines (0-239)

    // cycle 0 (idle)

    // cycles 1-256
    if (renderingEnabled) {
      if (rendering) {
        _renderPixel();
        _shiftBackground();
      }

      if (fetching) {
        switch (cycle % 8) {
          case 0:
            _loadShiftRegisters();
          case 1:
            _fetchNametable();
          case 3:
            _fetchAttributeTable();
          case 5:
            _fetchPatternTableHigh();
          case 7:
            _fetchPatternTableLow();
        }
      }
    }

    if (cycle <= 256 || cycle >= 328) {
      if (renderingEnabled && fetching) {
        if (cycle % 8 == 0) {
          _incrementX();
        }
      }
    }

    if (cycle == 256) {
      if (renderingEnabled) {
        _incrementY();
      }
    }

    if (cycle == 257) {
      if (renderingEnabled) {
        _copyHorizontalBits();
      }
    }

    if (linePreRender && cycle >= 280 && cycle <= 304) {
      if (renderingEnabled) {
        _copyVerticalBits();
      }
    }

    // cycles 257-320
    // for sprite 1..8
    // fetch pattern table tile low
    // fetch pattern table tile high

    // cycles 321-336
    // fetch tiles 1..2 for next scanline
    // fetch nametable byte
    // fetch attribute table byte
    // fetch pattern table tile low
    // fetch pattern table tile high

    // cycles 337-340
    // fetch nametable byte
    // fetch nametable byte

    // post-render scanline (240)
    // ppu idle

    // vblank start (scanline 241)
    // cycle 1
    // set vblank flag
    if (scanline == 241 && cycle == 1) {
      PPUSTATUS_V = 1;

      // trigger nmi if PPUCTRL.V is set
      if (PPUCTRL_V == 1) {
        bus.cpu.nmi = true;
      }
    }

    // vblank lines (242-260)
    // idle

    // pre-render scanline (261)
    if (linePreRender) {
      if (cycle == 1) {
        // clear overflow, sprite 0 hit, and vblank status
        PPUSTATUS_O = 0;
        PPUSTATUS_S = 0;
        PPUSTATUS_V = 0;
      }
    }

    // sprite evaluation
    _evaluateSprites();

    _updateCounters();
  }

  int _readPPUSTATUS() {
    final value = PPUSTATUS;

    PPUSTATUS_V = 0;
    w = 0;

    return value;
  }

  int _readOAMDATA() {
    return oam[OAMADDR];
  }

  int _readPPUDATA() {
    // return buffer from last read
    var value = PPUDATA;

    PPUDATA = read(v);

    // always return current palette data
    if (v >= 0x3F00) {
      value = PPUDATA;
    }

    v += PPUCTRL_I == 0 ? 1 : 32;

    return value;
  }

  void _writePPUCTRL(int value) {
    PPUCTRL = value;

    t = (t & 0xF3FF) | ((value & 0x03) << 10);
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
    PPUADDR = value;

    if (w == 0) {
      // t: .CDEFGH ........ <- d: ..CDEFGH
      // t: Z...... ........ <- 0 (bit Z is cleared)
      t = (t & 0x00FF) | ((value & 0x3F) << 8);
    } else {
      // t: ....... ABCDEFGH <- d: ABCDEFGH
      t = (t & 0xFF00) | value;
      v = t;
    }

    w = 1 - w;
  }

  void _writePPUDATA(int value) {
    PPUDATA = value;

    write(v, value);

    v += PPUCTRL_I == 0 ? 1 : 32;
  }

  void _updateCounters() {
    cycle++;

    if (scanline == 261 && cycle == 340 && frames.isOdd) {
      scanline = 0;
      cycle = 0;
      frames++;

      return;
    }

    if (cycle > 340) {
      cycle = 0;
      scanline++;

      if (scanline > 261) {
        scanline = 0;
        frames++;
      }
    }
  }

  void _loadShiftRegisters() {
    patternTableHighShift &= ~0xFF;
    patternTableHighShift |= patternTableHighLatch;

    patternTableLowShift &= ~0xFF;
    patternTableLowShift |= patternTableLowLatch;

    attribute = attributeTableLatch;
  }

  void _renderPixel() {
    final color = _getBackgroundPixelColor();

    final x = cycle - 1;
    final y = scanline;

    frameBuffer.setPixel(x, y, color);
  }

  int _getBackgroundPixelColor() {
    if (PPUMASK_b == 0) {
      return 0;
    }

    final patternHigh = (patternTableHighShift & 0x8000) >> (15 - x);
    final patternLow = (patternTableLowShift & 0x8000) >> (15 - x);

    final pattern = (patternHigh << 1) | patternLow;

    final paletteIndexHigh = (attributeTableHighShift & 0x80) >> (7 - x);
    final paletteIndexLow = (attributeTableLowShift & 0x80) >> (7 - x);

    final paletteIndex = (paletteIndexHigh << 1) | paletteIndexLow;

    final systemPaletteIndex = read(0x3F00 | (paletteIndex << 2) | pattern);

    return systemPalette[systemPaletteIndex] ?? 0;
  }

  void _shiftBackground() {
    patternTableHighShift <<= 1;
    patternTableLowShift <<= 1;

    attributeTableHighShift <<= 1;
    attributeTableLowShift <<= 1;

    attributeTableHighShift |= attribute & 0x1;
    attributeTableLowShift |= (attribute & 0x2) >> 1;
  }

  void _fetchNametable() {
    final address = 0x2000 | (v_coarseY << 5) | v_coarseX;

    nametableLatch = read(address);
  }

  void _fetchAttributeTable() {
    final address =
        0x23C0 | ((v_coarseY & 0x1C) << 1) | ((v_coarseX & 0x1C) >> 2);

    final value = read(address);

    // TODO bud-31.05.24 check
    final quadrant = (v_coarseY & 0x2) | ((v_coarseX & 0x2) >> 1);

    attributeTableLatch = switch (quadrant) {
      0 => value & 0x03, // top left
      1 => (value >> 2) & 0x03, // top right
      2 => (value >> 4) & 0x03, // bottom left
      3 => (value >> 6) & 0x03, // bottom right
      _ => 0,
    };
  }

  void _fetchPatternTableLow() {
    final address = PPUCTRL_B << 12 | nametableLatch << 4 | v_fineY;

    patternTableLowLatch = read(address);
  }

  void _fetchPatternTableHigh() {
    final address = PPUCTRL_B << 12 | nametableLatch << 4 | v_fineY + 8;

    patternTableHighLatch = read(address);
  }

  void _incrementX() {
    if (v_coarseX == 31) {
      v_coarseX = 0;
      v_nametableX = v_nametableX == 1 ? 0 : 1;
    } else {
      v_coarseX++;
    }
  }

  void _incrementY() {
    if (v_fineY < 7) {
      v_fineY++;

      return;
    }

    v_fineY = 0;

    if (v_coarseY == 29) {
      v_coarseY = 0;
      v_nametable = v_nametable == 0 ? 1 : 0;
    } else if (v_coarseY == 31) {
      v_coarseY = 0;
    } else {
      v_coarseY++;
    }
  }

  void _copyHorizontalBits() {
    // v: ....A.. ...BCDEF <- t: ....A.. ...BCDEF
    v_coarseX = t_coarseX;
    v_nametableX = t_nametableX;
  }

  void _copyVerticalBits() {
    // v: GHIA.BC DEF..... <- t: GHIA.BC DEF.....
    v_coarseY = t_coarseY;
    v_fineY = t_fineY;
    v_nametableY = t_nametableY;
  }

  void _evaluateSprites() {
    // visible scanlines (0-239)
    if (lineVisible) {
      if (cycle >= 1 && cycle <= 64) {
        secondaryOam.fillRange(0, secondaryOam.length, 0xFF);
      }

      if (cycle >= 1 && cycle <= 64) {
        // fetch sprite data
        // sprite evaluation
      }
    }

    // cycles 65-256
    // odd cycles: read from OAM
    // even cycles: write to secondary OAM, unless full:
    //  then read from secondary OAM instead

    // start at n = 0
    // read sprite n's Y-coordinate
    // unless 8 sprites have been found, write Y to secondary OAM
    // if Y is in range, copy rest of sprite data into secondary OAM
    // increment n
    // if n >= 64 / overflow to 0, break
    // if less than 8 sprites found, repeat
    // if exactly 8 sprites found, disable writes to secondary OAM

    // start at m = 0
    // fetch byte m for sprite n
    // if value is in Y range, set sprite overflow flag
    //  then read next 3 bytes of oam, increment m each time
    //  if m = 3, increment n
    // if value is not in range, increment n and m
    // if n overflows to 0, break
    // otherwise repeat

    // until hblank:
    // try to copy first OAM byte for sprite n into secondary OAM (fails)
    // increment n

    // cycles 257-320
    // from nesdev wiki:
    // Sprite fetches (8 sprites total, 8 cycles per sprite)
    // 1-4: Read T, tile number, attributes, and X
    //  of the selected sprite from secondary OAM
    // 5-8: Read X of the selected sprite from secondary OAM 4 times
    //  (while the PPU fetches the sprite tile data)

    // cycles 321-340
    // read first byte in secondary OAM
  }
}
