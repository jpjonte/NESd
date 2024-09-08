// ignore_for_file: non_constant_identifier_names

import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/ppu/frame_buffer.dart';
import 'package:nesd/nes/ppu/sprite_output.dart';
import 'package:nesd/payload_types/uint8_list.dart';

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
      ram: reader.get(uint8List),
      oam: reader.get(uint8List),
      secondaryOam: reader.get(uint8List),
      palette: reader.get(uint8List),
      frameBuffer: FrameBuffer.deserialize(reader),
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

  PPUState.dummy()
      : PPUCTRL = 0,
        PPUMASK = 0,
        PPUSTATUS = 0,
        OAMADDR = 0,
        OAMDATA = 0,
        PPUSCROLL = 0,
        PPUDATA = 0,
        v = 0,
        t = 0,
        x = 0,
        w = 0,
        ram = Uint8List(1),
        oam = Uint8List(1),
        secondaryOam = Uint8List(1),
        palette = Uint8List(1),
        frameBuffer = FrameBuffer(width: 0, height: 0),
        cycles = 0,
        cycle = 0,
        scanline = 0,
        frames = 0,
        nametableLatch = 0,
        patternTableHighLatch = 0,
        patternTableLowLatch = 0,
        patternTableHighShift = 0,
        patternTableLowShift = 0,
        attributeTableLatch = 0,
        attributeTableHighShift = 0,
        attributeTableLowShift = 0,
        attribute = 0,
        oamAddress = 0,
        oamBuffer = 0,
        spriteCount = 0,
        secondarySpriteCount = 0,
        sprite0OnNextLine = false,
        sprite0OnCurrentLine = false,
        spriteOutputs = [];

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
      ..set(uint8, 0) // version
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
      ..set(uint8List, ram)
      ..set(uint8List, oam)
      ..set(uint8List, secondaryOam)
      ..set(uint8List, palette);

    frameBuffer.serialize(writer);

    writer
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

class _LegacyPPUStateContract extends BinaryContract<PPUState>
    implements PPUState {
  _LegacyPPUStateContract() : super(PPUState.dummy());

  @override
  PPUState order(PPUState contract) {
    return PPUState(
      PPUCTRL: contract.PPUCTRL,
      PPUMASK: contract.PPUMASK,
      PPUSTATUS: contract.PPUSTATUS,
      OAMADDR: contract.OAMADDR,
      OAMDATA: contract.OAMDATA,
      PPUSCROLL: contract.PPUSCROLL,
      PPUDATA: contract.PPUDATA,
      v: contract.v,
      t: contract.t,
      x: contract.x,
      w: contract.w,
      ram: contract.ram,
      oam: contract.oam,
      secondaryOam: contract.secondaryOam,
      palette: contract.palette,
      frameBuffer: contract.frameBuffer,
      cycles: contract.cycles,
      cycle: contract.cycle,
      scanline: contract.scanline,
      frames: contract.frames,
      nametableLatch: contract.nametableLatch,
      patternTableHighLatch: contract.patternTableHighLatch,
      patternTableLowLatch: contract.patternTableLowLatch,
      patternTableHighShift: contract.patternTableHighShift,
      patternTableLowShift: contract.patternTableLowShift,
      attributeTableLatch: contract.attributeTableLatch,
      attributeTableHighShift: contract.attributeTableHighShift,
      attributeTableLowShift: contract.attributeTableLowShift,
      attribute: contract.attribute,
      oamAddress: contract.oamAddress,
      oamBuffer: contract.oamBuffer,
      spriteCount: contract.spriteCount,
      secondarySpriteCount: contract.secondarySpriteCount,
      sprite0OnNextLine: contract.sprite0OnNextLine,
      sprite0OnCurrentLine: contract.sprite0OnCurrentLine,
      spriteOutputs: contract.spriteOutputs,
    );
  }

  @override
  int get PPUCTRL => type(uint8, (o) => o.PPUCTRL);

  @override
  int get PPUMASK => type(uint8, (o) => o.PPUMASK);

  @override
  int get PPUSTATUS => type(uint8, (o) => o.PPUSTATUS);

  @override
  int get OAMADDR => type(uint8, (o) => o.OAMADDR);

  @override
  int get OAMDATA => type(uint8, (o) => o.OAMDATA);

  @override
  int get PPUSCROLL => type(uint8, (o) => o.PPUSCROLL);

  @override
  int get PPUDATA => type(uint8, (o) => o.PPUDATA);

  @override
  int get v => type(uint16, (o) => o.v);

  @override
  int get t => type(uint16, (o) => o.t);

  @override
  int get x => type(uint8, (o) => o.x);

  @override
  int get w => type(uint8, (o) => o.w);

  @override
  Uint8List get ram => Uint8List.fromList(type(list(uint8), (o) => o.ram));

  @override
  Uint8List get oam => Uint8List.fromList(type(list(uint8), (o) => o.oam));

  @override
  Uint8List get secondaryOam => Uint8List.fromList(
        type(list(uint8), (o) => o.secondaryOam),
      );

  @override
  Uint8List get palette => Uint8List.fromList(
        type(list(uint8), (o) => o.palette),
      );

  @override
  FrameBuffer get frameBuffer => type(
        legacyFrameBufferContract,
        (o) => o.frameBuffer,
      );

  @override
  int get attribute => type(uint8, (o) => o.attribute);

  @override
  int get attributeTableHighShift => type(
        uint8,
        (o) => o.attributeTableHighShift,
      );

  @override
  int get attributeTableLatch => type(uint8, (o) => o.attributeTableLatch);

  @override
  int get attributeTableLowShift => type(
        uint8,
        (o) => o.attributeTableLowShift,
      );

  @override
  int get cycle => type(uint8, (o) => o.cycle);

  @override
  int get cycles => type(uint64, (o) => o.cycles);

  @override
  int get frames => type(uint8, (o) => o.frames);

  @override
  int get nametableLatch => type(uint8, (o) => o.nametableLatch);

  @override
  int get oamAddress => type(uint8, (o) => o.oamAddress);

  @override
  int get oamBuffer => type(uint8, (o) => o.oamBuffer);

  @override
  int get patternTableHighLatch => type(uint8, (o) => o.patternTableHighLatch);

  @override
  int get patternTableHighShift => type(uint8, (o) => o.patternTableHighShift);

  @override
  int get patternTableLowLatch => type(uint8, (o) => o.patternTableLowLatch);

  @override
  int get patternTableLowShift => type(uint8, (o) => o.patternTableLowShift);

  @override
  int get scanline => type(uint8, (o) => o.scanline);

  @override
  int get secondarySpriteCount => type(uint8, (o) => o.secondarySpriteCount);

  @override
  bool get sprite0OnCurrentLine => type(boolean, (o) => o.sprite0OnCurrentLine);

  @override
  bool get sprite0OnNextLine => type(boolean, (o) => o.sprite0OnNextLine);

  @override
  int get spriteCount => type(uint8, (o) => o.spriteCount);

  @override
  List<SpriteOutputState> get spriteOutputs => type(
        list(legacySpriteOutputStateContract),
        (o) => o.spriteOutputs,
      );

  @override
  void serialize(PayloadWriter writer) => throw UnimplementedError();
}

final legacyPpuStateContract = _LegacyPPUStateContract();
