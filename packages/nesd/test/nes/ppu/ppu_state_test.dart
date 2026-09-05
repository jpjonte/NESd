import 'dart:typed_data';

import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/ppu/frame_buffer.dart';
import 'package:nesd/nes/ppu/ppu_state.dart';
import 'package:nesd/nes/ppu/sprite_output.dart';
import 'package:nesd/nes/serialization/nesd_uint64.dart';

import '../../test_roms/rom_robot.dart';

FrameBuffer buildFrameBuffer() {
  return FrameBuffer(width: 4, height: 4)
    ..setPixels(Uint8List.fromList(List.generate(64, (i) => (i * 7) & 0xff)));
}

/// Adversarial fixture: every widened field holds a value the old uint8
/// wire format cannot represent.
PPUState buildState({int decay = 0x5a}) {
  return PPUState(
    decay: decay,
    decayRefreshedAt: List<int>.generate(8, (i) => 1000 + i),
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
    patternTableHighShift: 0,
    patternTableLowShift: 0,
    attributeTableLatch: 2,
    attributeTableHighShift: 0,
    attributeTableLowShift: 0,
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
    bgWindow: Uint8List.fromList(List.generate(16, (i) => 0x60 | i)),
    patternTableLow2Latch: 0xf0,
    patternTableHigh2Latch: 0x0f,
  );
}

/// Same shape with every narrow field at a value the LEGACY uint8 format
/// can hold, for exercising the preserved v0/v1 readers.
PPUState buildLegacyState({int consoleCycles = 987654321}) {
  return PPUState(
    decayRefreshedAt: List<int>.filled(8, 0),
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
  expect(actual.decay, expected.decay);
  expect(actual.decayRefreshedAt, expected.decayRefreshedAt);
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
  final actualFrame = actual.frameBuffer;
  final expectedFrame = expected.frameBuffer;

  if (expectedFrame == null) {
    expect(actualFrame, isNull);
  } else {
    expect(actualFrame, isNotNull);
    expect(actualFrame!.width, expectedFrame.width);
    expect(actualFrame.height, expectedFrame.height);
    expect(actualFrame.pixels, expectedFrame.pixels);
  }
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

  state.frameBuffer!.serialize(writer);
}

void writeVersion3(PayloadWriter writer, PPUState state) {
  writer
    ..set(uint8, 3)
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

  state.frameBuffer!.serialize(writer);

  writer
    ..set(nesdUint64, state.consoleCycles)
    ..set(nesdUint64, state.cycles)
    ..set(uint16, state.cycle)
    ..set(uint16, state.scanline)
    ..set(uint32, state.frames)
    ..set(uint8, state.nametableLatch)
    ..set(uint8, state.patternTableHighLatch)
    ..set(uint8, state.patternTableLowLatch)
    ..set(uint16, state.patternTableHighShift)
    ..set(uint16, state.patternTableLowShift)
    ..set(uint8, state.attributeTableLatch)
    ..set(uint8, state.attributeTableHighShift)
    ..set(uint8, state.attributeTableLowShift)
    ..set(uint8, state.attribute)
    ..set(uint16, state.oamAddress)
    ..set(uint8, state.oamBuffer)
    ..set(uint8, state.spriteCount)
    ..set(uint8, state.secondarySpriteCount)
    ..set(boolean, state.sprite0OnNextLine)
    ..set(boolean, state.sprite0OnCurrentLine);

  SpriteOutputState.serializeList(writer, state.spriteOutputs);

  writer
    ..set(uint8, state.decay)
    ..set(uint32List(), Uint32List.fromList(state.decayRefreshedAt));
}

void writeVersion4(PayloadWriter writer, PPUState state) {
  writer
    ..set(uint8, 4)
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
    ..set(uint8List(lengthType: uint32), state.palette)
    ..set(uint8, 1);

  state.frameBuffer!.serialize(writer);

  writer
    ..set(nesdUint64, state.consoleCycles)
    ..set(nesdUint64, state.cycles)
    ..set(uint16, state.cycle)
    ..set(uint16, state.scanline)
    ..set(uint32, state.frames)
    ..set(uint8, state.nametableLatch)
    ..set(uint8, state.patternTableHighLatch)
    ..set(uint8, state.patternTableLowLatch)
    ..set(uint16, state.patternTableHighShift)
    ..set(uint16, state.patternTableLowShift)
    ..set(uint8, state.attributeTableLatch)
    ..set(uint8, state.attributeTableHighShift)
    ..set(uint8, state.attributeTableLowShift)
    ..set(uint8, state.attribute)
    ..set(uint16, state.oamAddress)
    ..set(uint8, state.oamBuffer)
    ..set(uint8, state.spriteCount)
    ..set(uint8, state.secondarySpriteCount)
    ..set(boolean, state.sprite0OnNextLine)
    ..set(boolean, state.sprite0OnCurrentLine);

  SpriteOutputState.serializeList(writer, state.spriteOutputs);

  writer
    ..set(uint8, state.decay)
    ..set(uint32List(), Uint32List.fromList(state.decayRefreshedAt));
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
  test('serialize writes version 5 and round-trips adversarial values', () {
    final original = buildState();

    final writer = Payload.write();
    original.serialize(writer);
    final bytes = binarize(writer);

    expect(bytes[0], 5, reason: 'PPUState version');

    final decoded = PPUState.deserialize(Payload.read(bytes));

    expectStatesEqual(decoded, original);
  });

  test('omits the frame when asked and restores it as null', () {
    final original = buildState();

    final writer = Payload.write();
    original.serialize(writer, includeFrame: false);
    final bytes = binarize(writer);

    final decoded = PPUState.deserialize(Payload.read(bytes));

    expect(decoded.frameBuffer, isNull);
    expect(decoded.ram, original.ram);
    expect(decoded.decayRefreshedAt, original.decayRefreshedAt);
  });

  test('a frameless payload is much smaller than one with the frame', () {
    final original = buildState();

    final withFrame = Payload.write();
    original.serialize(withFrame);

    final withoutFrame = Payload.write();
    original.serialize(withoutFrame, includeFrame: false);

    expect(
      binarize(withoutFrame).length,
      lessThan(binarize(withFrame).length - 64),
    );
  });

  test('still reads version 3 payloads', () {
    final original = buildState();

    final writer = Payload.write();
    writeVersion3(writer, original);

    final decoded = PPUState.deserialize(Payload.read(binarize(writer)));

    expectStatesEqual(decoded, original);
  });

  test('still reads version 4 payloads', () {
    final original = buildState();

    final writer = Payload.write();
    writeVersion4(writer, original);

    final decoded = PPUState.deserialize(Payload.read(binarize(writer)));

    expectStatesEqual(decoded, original);
  });

  test('v5 round-trips the 7-bit background window and plane latches', () {
    final state = buildState();

    final writer = Payload.write();
    state.serialize(writer);

    final restored = PPUState.deserialize(Payload.read(binarize(writer)));

    expect(restored.bgWindow, state.bgWindow);
    expect(restored.patternTableLow2Latch, state.patternTableLow2Latch);
    expect(restored.patternTableHigh2Latch, state.patternTableHigh2Latch);
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

  test('restoring a frameless state leaves the live pixels alone', () {
    final robot = RomRobot('../../roms/test/nestest/nestest.nes');
    final ppu = robot.nes.ppu;

    ppu.frameBuffer.pixels[0] = 0xab;

    final writer = Payload.write();
    ppu.state.serialize(writer, includeFrame: false);
    final frameless = PPUState.deserialize(Payload.read(binarize(writer)));

    ppu.frameBuffer.pixels[0] = 0xcd;
    ppu.state = frameless;

    expect(ppu.frameBuffer.pixels[0], 0xcd);
  });

  test('sprite outputs round-trip the 4bpp plane bytes', () {
    const state = SpriteOutputState(
      patternLow: 1,
      patternHigh: 2,
      patternLow2: 0xa5,
      patternHigh2: 0x5a,
      attribute: 3,
      x: 4,
    );

    final writer = Payload.write();
    state.serialize(writer);

    final restored = SpriteOutputState.deserialize(
      Payload.read(binarize(writer)),
    );

    expect(restored.patternLow2, 0xa5);
    expect(restored.patternHigh2, 0x5a);
  });
}
