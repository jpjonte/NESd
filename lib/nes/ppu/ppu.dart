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
  0x20: 0xffffff,
  0x21: 0x53aeff,
  0x22: 0x9085ff,
  0x23: 0xd365ff,
  0x24: 0xff57ff,
  0x25: 0xff5dcf,
  0x26: 0xff7757,
  0x27: 0xfa9e00,
  0x28: 0xbdc700,
  0x29: 0x7ae700,
  0x2a: 0x43f611,
  0x2b: 0x26ef7e,
  0x2c: 0x2cd5f6,
  0x2d: 0x4e4e4e,
  0x2e: 0x000000,
  0x2f: 0x000000,
  0x30: 0xffffff,
  0x31: 0xb6e1ff,
  0x32: 0xced1ff,
  0x33: 0xe9c3ff,
  0x34: 0xffbcff,
  0x35: 0xffbdf4,
  0x36: 0xffc6c3,
  0x37: 0xffd59a,
  0x38: 0xe9e681,
  0x39: 0xcef481,
  0x3a: 0xb6fb9a,
  0x3b: 0xa9fac3,
  0x3c: 0xa9f0f4,
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

  // TODO bud-01.06.24 implement
  int get PPUMASK_Gr => PPUMASK.bit(0); // greyscale
  // TODO bud-01.06.24 implement
  int get PPUMASK_m => PPUMASK.bit(1); // show background in leftmost 8 pixels
  // TODO bud-01.06.24 implement
  int get PPUMASK_M => PPUMASK.bit(2); // show sprites in leftmost 8 pixels
  int get PPUMASK_b => PPUMASK.bit(3); // show background
  int get PPUMASK_s => PPUMASK.bit(4); // show sprites
  // TODO bud-01.06.24 implement
  int get PPUMASK_R => PPUMASK.bit(5); // emphasize red
  // TODO bud-01.06.24 implement
  int get PPUMASK_G => PPUMASK.bit(6); // emphasize green
  // TODO bud-01.06.24 implement
  int get PPUMASK_B => PPUMASK.bit(7); // emphasize blue

  set PPUMASK_Gr(int value) => PPUMASK = PPUMASK.setBit(0, value);
  set PPUMASK_m(int value) => PPUMASK = PPUMASK.setBit(1, value);
  set PPUMASK_M(int value) => PPUMASK = PPUMASK.setBit(2, value);
  set PPUMASK_b(int value) => PPUMASK = PPUMASK.setBit(3, value);
  set PPUMASK_s(int value) => PPUMASK = PPUMASK.setBit(4, value);
  set PPUMASK_R(int value) => PPUMASK = PPUMASK.setBit(5, value);
  set PPUMASK_G(int value) => PPUMASK = PPUMASK.setBit(6, value);
  set PPUMASK_B(int value) => PPUMASK = PPUMASK.setBit(7, value);

  // TODO bud-01.06.24 implement
  int get PPUSTATUS_O => PPUSTATUS.bit(5); // sprite overflow
  // TODO bud-01.06.24 implement
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

  int oamN = 0x00;
  int oamBuffer = 0;
  int spriteCount = 0;
  int secondarySpriteCount = 0;

  Uint8List spritePatternLow = Uint8List(8);
  Uint8List spritePatternHigh = Uint8List(8);

  Uint8List spriteAttribute = Uint8List(8);
  Uint8List spriteX = Uint8List(8);

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
        _writeOAMDATA(value);
      case 0x2005:
        _writePPUSCROLL(value);
      case 0x2006:
        _writePPUADDR(value);
      case 0x2007:
        _writePPUDATA(value);
    }
  }

  void writeOAM(int offset, int value) {
    oam[(OAMADDR + offset) & 0xFF] = value;
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

    if (linePreRender) {
      if (cycle == 1) {
        // clear overflow, sprite 0 hit, and vblank status
        PPUSTATUS_O = 0;
        PPUSTATUS_S = 0;
        PPUSTATUS_V = 0;
      }
    }

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

  void _writeOAMDATA(int value) {
    if (rendering) {
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
    }

    w = 1 - w;
  }

  void _writePPUDATA(int value) {
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
    final color = _getPixelColor();

    final x = cycle - 1;
    final y = scanline;

    final paletteColor = read(0x3F00 | color);

    final systemColor = systemPalette[paletteColor] ?? 0;

    frameBuffer.setPixel(x, y, systemColor);
  }

  int _getPixelColor() {
    final backgroundColor = _getBackgroundPixelColor();

    final spriteColor = _getSpritePixelColor();
    final spritePriority = spriteColor.bit(4);
    final spriteColorValue = spriteColor & 0xf;

    if (PPUMASK_b == 0 && PPUMASK_s == 0) {
      return 0;
    }

    if (PPUMASK_s == 0) {
      return backgroundColor;
    }

    if (PPUMASK_b == 0) {
      return spriteColorValue.setBit(4, 1);
    }

    if (backgroundColor & 0x3 == 0) {
      return spriteColorValue.setBit(4, 1);
    }

    if (spriteColorValue & 0x3 == 0) {
      return backgroundColor;
    }

    if (spritePriority == 1) {
      return backgroundColor;
    }

    return spriteColorValue.setBit(4, 1);
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

    return (paletteIndex << 2) | pattern;
  }

  int _getSpritePixelColor() {
    final currentX = cycle - 1;

    for (var sprite = 0; sprite < spriteCount; sprite++) {
      // TODO bud-01.06.24 implement a proper algorithm
      final x = spriteX[sprite];
      final xOffset = currentX - x;

      if (xOffset < 0 || xOffset > 7) {
        continue;
      }

      final attribute = spriteAttribute[sprite];
      final palette = attribute & 0x3;
      final priority = attribute.bit(5);
      final flipH = attribute.bit(6);

      final fineX = flipH == 1 ? xOffset : 7 - xOffset;

      final patternLow = spritePatternLow[sprite];
      final patternHigh = spritePatternHigh[sprite];
      final pattern =
          ((patternHigh.bit(fineX) << 1) | patternLow.bit(fineX)) & 0x3;

      if (pattern == 0) {
        continue;
      }

      return priority << 4 | palette << 2 | pattern;
    }

    return 0;
  }

  void _shiftBackground() {
    patternTableHighShift <<= 1;
    patternTableLowShift <<= 1;

    attributeTableHighShift <<= 1;
    attributeTableLowShift <<= 1;

    attributeTableHighShift |= (attribute & 0x2) >> 1;
    attributeTableLowShift |= attribute & 0x1;
  }

  void _fetchNametable() {
    final address = 0x2000 | v_coarseScroll;

    nametableLatch = read(address);
  }

  void _fetchAttributeTable() {
    final address = 0x23c0 |
        (v_nametable << 10) |
        ((v_coarseY & 0x1C) << 1) | // we select the attribute table
        ((v_coarseX & 0x1C) >> 2); // using bits 2..4 of the tile x and y

    final value = read(address);

    // attribute table byte layout: DDCCBBAA
    // quadrants A, B, C, D = Top Left, Top Right, Bottom Left, Bottom Right
    // each quadrant covers 2x2 tiles
    // => we select the quadrant using bit 2 of the tile x and y coordinates

    // result is 0, 2, 4, or 6
    // this is the location of the low bit of the quadrant in the fetched byte
    final quadrantShift = ((v_coarseY & 0x2) << 1) | (v_coarseX & 0x2);

    attributeTableLatch = (value >> quadrantShift) & 0x03;
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
        secondaryOam[(cycle - 1) >> 1] = 0xff;
      }

      if (cycle >= 65 && cycle <= 256) {
        if (cycle == 65) {
          oamN = OAMADDR;
          secondarySpriteCount = 0;
          oamBuffer = 0;
        }

        if (cycle.isOdd) {
          // read from OAM
          oamBuffer = oam[oamN & 0xff];
        } else {
          // TODO bud-01.06.24 implement a proper algorithm
          // write to secondary OAM, unless full
          if (secondarySpriteCount < 8 && oamN <= 252) {
            final y = oamBuffer;

            if (scanline >= y && scanline < y + 8) {
              secondaryOam[secondarySpriteCount * 4] = y;
              secondaryOam[secondarySpriteCount * 4 + 1] = oam[oamN + 1];
              secondaryOam[secondarySpriteCount * 4 + 2] = oam[oamN + 2];
              secondaryOam[secondarySpriteCount * 4 + 3] = oam[oamN + 3];

              secondarySpriteCount++;
            }

            oamN += 4;

            // TODO bud-01.06.24 implement sprite overflow flag
            // start at m = 0
            // fetch byte m for sprite n
            // if value is in Y range, set sprite overflow flag
            //  then read next 3 bytes of oam, increment m each time
            //  if m = 3, increment n
            // if value is not in range, increment n and m
            // if n overflows to 0, break
            // otherwise repeat
          }
        }
      }

      if (cycle >= 257 && cycle <= 320) {
        if (cycle == 257) {
          spriteCount = secondarySpriteCount;
        }

        final subcycle = cycle - 257;
        final sprite = subcycle ~/ 8;
        final offset = subcycle % 8;

        switch (offset) {
          case 2:
            spriteAttribute[sprite] = secondaryOam[sprite * 4 + 2];
          case 3:
            spriteX[sprite] = secondaryOam[sprite * 4 + 3];
          case 4:
            final y = secondaryOam[sprite * 4];
            final tile = secondaryOam[sprite * 4 + 1];
            final attribute = spriteAttribute[sprite];
            final flipV = attribute.bit(7);
            final yOffset = scanline - y;
            final fineY = flipV == 0 ? yOffset : 7 - yOffset;

            spritePatternLow[sprite] =
                read(PPUCTRL_S << 12 | tile << 4 | fineY);
            spritePatternHigh[sprite] =
                read(PPUCTRL_S << 12 | tile << 4 | fineY + 8);
        }
      }
    }
  }
}
