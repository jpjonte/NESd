// the register names don't match dart naming conventions
// ignore_for_file: non_constant_identifier_names

import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/ppu/frame_buffer.dart';
import 'package:nesd/nes/ppu/sprite_output.dart';

class PPUState {
  PPUState({
    required this.PPUCTRL,
    required this.PPUMASK,
    required this.PPUSTATUS,
    required this.OAMADDR,
    required this.OAMDATA,
    required this.PPUSCROLL,
    required this.PPUDATA,
    required this.v,
    required this.t,
    required this.x,
    required this.w,
    required this.ram,
    required this.oam,
    required this.secondaryOam,
    required this.palette,
    required this.frameBuffer,
    required this.consoleCycles,
    required this.cycles,
    required this.cycle,
    required this.scanline,
    required this.frames,
    required this.nametableLatch,
    required this.patternTableHighLatch,
    required this.patternTableLowLatch,
    required this.patternTableHighShift,
    required this.patternTableLowShift,
    required this.attributeTableLatch,
    required this.attributeTableHighShift,
    required this.attributeTableLowShift,
    required this.attribute,
    required this.oamAddress,
    required this.oamBuffer,
    required this.spriteCount,
    required this.secondarySpriteCount,
    required this.sprite0OnNextLine,
    required this.sprite0OnCurrentLine,
    required this.spriteOutputs,
  });

  factory PPUState.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => PPUState.version0(reader),
      1 => PPUState.version1(reader),
      _ => throw InvalidSerializationVersion('PPUState', version),
    };
  }

  factory PPUState.version0(PayloadReader reader) {
    return PPUState(
      PPUCTRL: reader.get(uint8),
      PPUMASK: reader.get(uint8),
      PPUSTATUS: reader.get(uint8),
      OAMADDR: reader.get(uint8),
      OAMDATA: reader.get(uint8),
      PPUSCROLL: reader.get(uint8),
      PPUDATA: reader.get(uint8),
      v: reader.get(uint16),
      t: reader.get(uint16),
      x: reader.get(uint8),
      w: reader.get(uint8),
      ram: reader.get(uint8List(lengthType: uint32)),
      oam: reader.get(uint8List(lengthType: uint32)),
      secondaryOam: reader.get(uint8List(lengthType: uint32)),
      palette: reader.get(uint8List(lengthType: uint32)),
      frameBuffer: FrameBuffer.deserialize(reader),
      consoleCycles: 0,
      cycles: reader.get(uint64),
      cycle: reader.get(uint8),
      scanline: reader.get(uint8),
      frames: reader.get(uint8),
      nametableLatch: reader.get(uint8),
      patternTableHighLatch: reader.get(uint8),
      patternTableLowLatch: reader.get(uint8),
      patternTableHighShift: reader.get(uint8),
      patternTableLowShift: reader.get(uint8),
      attributeTableLatch: reader.get(uint8),
      attributeTableHighShift: reader.get(uint8),
      attributeTableLowShift: reader.get(uint8),
      attribute: reader.get(uint8),
      oamAddress: reader.get(uint8),
      oamBuffer: reader.get(uint8),
      spriteCount: reader.get(uint8),
      secondarySpriteCount: reader.get(uint8),
      sprite0OnNextLine: reader.get(boolean),
      sprite0OnCurrentLine: reader.get(boolean),
      spriteOutputs: SpriteOutputState.deserializeList(reader),
    );
  }

  factory PPUState.version1(PayloadReader reader) {
    return PPUState(
      PPUCTRL: reader.get(uint8),
      PPUMASK: reader.get(uint8),
      PPUSTATUS: reader.get(uint8),
      OAMADDR: reader.get(uint8),
      OAMDATA: reader.get(uint8),
      PPUSCROLL: reader.get(uint8),
      PPUDATA: reader.get(uint8),
      v: reader.get(uint16),
      t: reader.get(uint16),
      x: reader.get(uint8),
      w: reader.get(uint8),
      ram: reader.get(uint8List(lengthType: uint32)),
      oam: reader.get(uint8List(lengthType: uint32)),
      secondaryOam: reader.get(uint8List(lengthType: uint32)),
      palette: reader.get(uint8List(lengthType: uint32)),
      frameBuffer: FrameBuffer.deserialize(reader),
      consoleCycles: reader.get(uint64),
      cycles: reader.get(uint64),
      cycle: reader.get(uint8),
      scanline: reader.get(uint8),
      frames: reader.get(uint8),
      nametableLatch: reader.get(uint8),
      patternTableHighLatch: reader.get(uint8),
      patternTableLowLatch: reader.get(uint8),
      patternTableHighShift: reader.get(uint8),
      patternTableLowShift: reader.get(uint8),
      attributeTableLatch: reader.get(uint8),
      attributeTableHighShift: reader.get(uint8),
      attributeTableLowShift: reader.get(uint8),
      attribute: reader.get(uint8),
      oamAddress: reader.get(uint8),
      oamBuffer: reader.get(uint8),
      spriteCount: reader.get(uint8),
      secondarySpriteCount: reader.get(uint8),
      sprite0OnNextLine: reader.get(boolean),
      sprite0OnCurrentLine: reader.get(boolean),
      spriteOutputs: SpriteOutputState.deserializeList(reader),
    );
  }

  final int PPUCTRL;
  final int PPUMASK;
  final int PPUSTATUS;
  final int OAMADDR;
  final int OAMDATA;
  final int PPUSCROLL;
  final int PPUDATA;

  final int v;
  final int t;
  final int x;
  final int w;

  final Uint8List ram;
  final Uint8List oam;
  final Uint8List secondaryOam;
  final Uint8List palette;

  final FrameBuffer frameBuffer;

  final int consoleCycles;
  final int cycles;
  final int cycle;
  final int scanline;
  final int frames;

  final int nametableLatch;

  final int patternTableHighLatch;
  final int patternTableLowLatch;

  final int patternTableHighShift;
  final int patternTableLowShift;

  final int attributeTableLatch;

  final int attributeTableHighShift;
  final int attributeTableLowShift;

  final int attribute;

  final int oamAddress;
  final int oamBuffer;

  final int spriteCount;
  final int secondarySpriteCount;

  final bool sprite0OnNextLine;
  final bool sprite0OnCurrentLine;

  final List<SpriteOutputState> spriteOutputs;

  void serialize(PayloadWriter writer) {
    writer
      ..set(uint8, 1) // version
      ..set(uint8, PPUCTRL)
      ..set(uint8, PPUMASK)
      ..set(uint8, PPUSTATUS)
      ..set(uint8, OAMADDR)
      ..set(uint8, OAMDATA)
      ..set(uint8, PPUSCROLL)
      ..set(uint8, PPUDATA)
      ..set(uint16, v)
      ..set(uint16, t)
      ..set(uint8, x)
      ..set(uint8, w)
      ..set(uint8List(lengthType: uint32), ram)
      ..set(uint8List(lengthType: uint32), oam)
      ..set(uint8List(lengthType: uint32), secondaryOam)
      ..set(uint8List(lengthType: uint32), palette);

    frameBuffer.serialize(writer);

    writer
      ..set(uint64, consoleCycles)
      ..set(uint64, cycles)
      ..set(uint8, cycle)
      ..set(uint8, scanline)
      ..set(uint8, frames)
      ..set(uint8, nametableLatch)
      ..set(uint8, patternTableHighLatch)
      ..set(uint8, patternTableLowLatch)
      ..set(uint8, patternTableHighShift)
      ..set(uint8, patternTableLowShift)
      ..set(uint8, attributeTableLatch)
      ..set(uint8, attributeTableHighShift)
      ..set(uint8, attributeTableLowShift)
      ..set(uint8, attribute)
      ..set(uint8, oamAddress)
      ..set(uint8, oamBuffer)
      ..set(uint8, spriteCount)
      ..set(uint8, secondarySpriteCount)
      ..set(boolean, sprite0OnNextLine)
      ..set(boolean, sprite0OnCurrentLine);

    SpriteOutputState.serializeList(writer, spriteOutputs);
  }
}
