import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/ppu/frame_buffer.dart';
import 'package:nesd/nes/ppu/ppu_state.dart';
import 'package:nesd/nes/ppu/sprite_output.dart';

FrameBuffer buildFrameBuffer() {
  return FrameBuffer(width: 4, height: 4)
    ..setPixels(Uint8List.fromList(List.generate(64, (i) => (i * 7) & 0xff)));
}

/// Adversarial fixture: every widened field holds a value the old uint8
/// wire format cannot represent.
PPUState buildState() {
  return PPUState(
    PPUCTRL: 0x90,
    PPUMASK: 0x1e,
    PPUSTATUS: 0xa0,
    OAMADDR: 0x10,
    OAMDATA: 0x42,
    PPUSCROLL: 0x21,
    PPUDATA: 0x33,
    v: 0x2abc,
    t: 0x2def,
    x: 5,
    w: 1,
    ram: Uint8List.fromList(List.generate(0x800, (i) => (i * 13) & 0xff)),
    oam: Uint8List.fromList(List.generate(0x100, (i) => (i * 17) & 0xff)),
    secondaryOam: Uint8List.fromList(
      List.generate(0x20, (i) => (i * 19) & 0xff),
    ),
    palette: Uint8List.fromList(List.generate(0x20, (i) => (i * 23) & 0x3f)),
    frameBuffer: buildFrameBuffer(),
    consoleCycles: 987654321,
    cycles: 123456789,
    cycle: 340,
    scanline: 311, // PAL pre-render line
    frames: 70000, // exceeds uint16 too — proves uint32
    nametableLatch: 0x24,
    patternTableHighLatch: 0x5a,
    patternTableLowLatch: 0xa5,
    patternTableHighShift: 0xabcd,
    patternTableLowShift: 0x1234,
    attributeTableLatch: 2,
    attributeTableHighShift: 0xf0,
    attributeTableLowShift: 0x0f,
    attribute: 3,
    oamAddress: 257, // sprite evaluation may stop as high as 257
    oamBuffer: 0x77,
    spriteCount: 8,
    secondarySpriteCount: 8,
    sprite0OnNextLine: true,
    sprite0OnCurrentLine: false,
    spriteOutputs: const [
      SpriteOutputState(patternLow: 1, patternHigh: 2, attribute: 3, x: 4),
      SpriteOutputState(patternLow: 5, patternHigh: 6, attribute: 7, x: 8),
    ],
  );
}

/// Same shape with every narrow field at a value the LEGACY uint8 format
/// can hold, for exercising the preserved v0/v1 readers.
PPUState buildLegacyState({int consoleCycles = 987654321}) {
  return PPUState(
    PPUCTRL: 0x90,
    PPUMASK: 0x1e,
    PPUSTATUS: 0xa0,
    OAMADDR: 0x10,
    OAMDATA: 0x42,
    PPUSCROLL: 0x21,
    PPUDATA: 0x33,
    v: 0x2abc,
    t: 0x2def,
    x: 5,
    w: 1,
    ram: Uint8List.fromList(List.generate(0x800, (i) => (i * 13) & 0xff)),
    oam: Uint8List.fromList(List.generate(0x100, (i) => (i * 17) & 0xff)),
    secondaryOam: Uint8List.fromList(
      List.generate(0x20, (i) => (i * 19) & 0xff),
    ),
    palette: Uint8List.fromList(List.generate(0x20, (i) => (i * 23) & 0x3f)),
    frameBuffer: buildFrameBuffer(),
    consoleCycles: consoleCycles,
    cycles: 123456789,
    cycle: 200,
    scanline: 241,
    frames: 100,
    nametableLatch: 0x24,
    patternTableHighLatch: 0x5a,
    patternTableLowLatch: 0xa5,
    patternTableHighShift: 0xcd,
    patternTableLowShift: 0x34,
    attributeTableLatch: 2,
    attributeTableHighShift: 0xf0,
    attributeTableLowShift: 0x0f,
    attribute: 3,
    oamAddress: 33,
    oamBuffer: 0x77,
    spriteCount: 8,
    secondarySpriteCount: 8,
    sprite0OnNextLine: true,
    sprite0OnCurrentLine: false,
    spriteOutputs: const [
      SpriteOutputState(patternLow: 1, patternHigh: 2, attribute: 3, x: 4),
    ],
  );
}

void expectStatesEqual(PPUState actual, PPUState expected) {
  expect(actual.PPUCTRL, expected.PPUCTRL);
  expect(actual.PPUMASK, expected.PPUMASK);
  expect(actual.PPUSTATUS, expected.PPUSTATUS);
  expect(actual.OAMADDR, expected.OAMADDR);
  expect(actual.OAMDATA, expected.OAMDATA);
  expect(actual.PPUSCROLL, expected.PPUSCROLL);
  expect(actual.PPUDATA, expected.PPUDATA);
  expect(actual.v, expected.v);
  expect(actual.t, expected.t);
  expect(actual.x, expected.x);
  expect(actual.w, expected.w);
  expect(actual.ram, expected.ram);
  expect(actual.oam, expected.oam);
  expect(actual.secondaryOam, expected.secondaryOam);
  expect(actual.palette, expected.palette);
  expect(actual.frameBuffer.width, expected.frameBuffer.width);
  expect(actual.frameBuffer.height, expected.frameBuffer.height);
  expect(actual.frameBuffer.pixels, expected.frameBuffer.pixels);
  expect(actual.consoleCycles, expected.consoleCycles);
  expect(actual.cycles, expected.cycles);
  expect(actual.cycle, expected.cycle);
  expect(actual.scanline, expected.scanline);
  expect(actual.frames, expected.frames);
  expect(actual.nametableLatch, expected.nametableLatch);
  expect(actual.patternTableHighLatch, expected.patternTableHighLatch);
  expect(actual.patternTableLowLatch, expected.patternTableLowLatch);
  expect(actual.patternTableHighShift, expected.patternTableHighShift);
  expect(actual.patternTableLowShift, expected.patternTableLowShift);
  expect(actual.attributeTableLatch, expected.attributeTableLatch);
  expect(actual.attributeTableHighShift, expected.attributeTableHighShift);
  expect(actual.attributeTableLowShift, expected.attributeTableLowShift);
  expect(actual.attribute, expected.attribute);
  expect(actual.oamAddress, expected.oamAddress);
  expect(actual.oamBuffer, expected.oamBuffer);
  expect(actual.spriteCount, expected.spriteCount);
  expect(actual.secondarySpriteCount, expected.secondarySpriteCount);
  expect(actual.sprite0OnNextLine, expected.sprite0OnNextLine);
  expect(actual.sprite0OnCurrentLine, expected.sprite0OnCurrentLine);
  expect(actual.spriteOutputs.length, expected.spriteOutputs.length);

  for (var i = 0; i < expected.spriteOutputs.length; i++) {
    expect(
      actual.spriteOutputs[i].patternLow,
      expected.spriteOutputs[i].patternLow,
    );
    expect(
      actual.spriteOutputs[i].patternHigh,
      expected.spriteOutputs[i].patternHigh,
    );
    expect(
      actual.spriteOutputs[i].attribute,
      expected.spriteOutputs[i].attribute,
    );
    expect(actual.spriteOutputs[i].x, expected.spriteOutputs[i].x);
  }
}

void writeLegacyBody(PayloadWriter writer, PPUState state) {
  writer
    ..set(uint8, state.PPUCTRL)
    ..set(uint8, state.PPUMASK)
    ..set(uint8, state.PPUSTATUS)
    ..set(uint8, state.OAMADDR)
    ..set(uint8, state.OAMDATA)
    ..set(uint8, state.PPUSCROLL)
    ..set(uint8, state.PPUDATA)
    ..set(uint16, state.v)
    ..set(uint16, state.t)
    ..set(uint8, state.x)
    ..set(uint8, state.w)
    ..set(uint8List(lengthType: uint32), state.ram)
    ..set(uint8List(lengthType: uint32), state.oam)
    ..set(uint8List(lengthType: uint32), state.secondaryOam)
    ..set(uint8List(lengthType: uint32), state.palette);

  state.frameBuffer.serialize(writer);
}

void writeLegacyTail(PayloadWriter writer, PPUState state) {
  writer
    ..set(uint64, state.cycles)
    ..set(uint8, state.cycle)
    ..set(uint8, state.scanline)
    ..set(uint8, state.frames)
    ..set(uint8, state.nametableLatch)
    ..set(uint8, state.patternTableHighLatch)
    ..set(uint8, state.patternTableLowLatch)
    ..set(uint8, state.patternTableHighShift)
    ..set(uint8, state.patternTableLowShift)
    ..set(uint8, state.attributeTableLatch)
    ..set(uint8, state.attributeTableHighShift)
    ..set(uint8, state.attributeTableLowShift)
    ..set(uint8, state.attribute)
    ..set(uint8, state.oamAddress)
    ..set(uint8, state.oamBuffer)
    ..set(uint8, state.spriteCount)
    ..set(uint8, state.secondarySpriteCount)
    ..set(boolean, state.sprite0OnNextLine)
    ..set(boolean, state.sprite0OnCurrentLine);

  SpriteOutputState.serializeList(writer, state.spriteOutputs);
}

void main() {
  test('serialize writes version 2 and round-trips adversarial values', () {
    final original = buildState();

    final writer = Payload.write();
    original.serialize(writer);
    final bytes = binarize(writer);

    expect(bytes[0], 2, reason: 'PPUState version');

    final decoded = PPUState.deserialize(Payload.read(bytes));

    expectStatesEqual(decoded, original);
  });

  test('still reads legacy version 1 payloads', () {
    final original = buildLegacyState();

    // replicate the exact v1 wire format the previous code produced
    final writer = Payload.write()..set(uint8, 1);

    writeLegacyBody(writer, original);

    writer.set(uint64, original.consoleCycles);

    writeLegacyTail(writer, original);

    final decoded = PPUState.deserialize(Payload.read(binarize(writer)));

    expectStatesEqual(decoded, original);
  });

  test('still reads legacy version 0 payloads', () {
    // v0 has no consoleCycles field; the reader defaults it to 0
    final original = buildLegacyState(consoleCycles: 0);

    final writer = Payload.write()..set(uint8, 0);

    writeLegacyBody(writer, original);
    writeLegacyTail(writer, original);

    final decoded = PPUState.deserialize(Payload.read(binarize(writer)));

    expectStatesEqual(decoded, original);
  });
}
