// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

import 'package:nes/nes/bus.dart';
import 'package:nes/nes/ppu/frame_buffer.dart';

class PPU {
  PPU(this.bus);

  final Bus bus;

  int PPUCTRL = 0;
  int PPUMASK = 0;
  int PPUSTATUS = 0;
  int OAMADDR = 0;
  int OAMDATA = 0;
  int PPUSCROLL = 0;
  int PPUADDR = 0;
  int PPUDATA = 0;
  int OAMDMA = 0;

  final Uint8List ram = Uint8List(0x0800);
  final Uint8List oam = Uint8List(0x0100);
  final Uint8List palette = Uint8List(0x0020);

  final FrameBuffer frameBuffer = FrameBuffer(width: 256, height: 240);

  int cycle = 0;
  int scanline = 0;

  void reset() {
    cycle = 0;
    scanline = 0;
  }

  int read(int address) => bus.ppuRead(address);

  void write(int address, int value) => bus.ppuWrite(address, value);

  void step() {
    cycle++;
  }
}
