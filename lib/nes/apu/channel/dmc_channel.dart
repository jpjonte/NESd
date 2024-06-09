import 'package:nes/extension/bit_extension.dart';
import 'package:nes/nes/apu/tables.dart';
import 'package:nes/nes/bus.dart';

class DMCChannel {
  bool enabled = false;

  bool irqEnabled = false;
  bool interrupt = false;
  bool loop = false;
  bool silence = false;

  int buffer = 0;
  int rate = 0;

  int bitsRemaining = 0;
  int shiftRegister = 0;

  int timer = 0;

  int level = 0;

  int sampleAddress = 0;
  int sampleLength = 0;

  int address = 0;
  int length = 0;

  bool sampleLoaded = false;

  bool startDma = false;

  void reset() {
    enabled = false;
    irqEnabled = false;
    interrupt = false;
    loop = false;
    silence = false;
    sampleLoaded = false;
    rate = 0;
    level = 0;
    timer = 0;
    buffer = 0;
    bitsRemaining = 0;
    shiftRegister = 0;
    sampleAddress = 0;
    sampleLength = 0;
    address = 0;
    length = 0;
  }

  void step() {
    if (timer > 0) {
      timer--;
    } else {
      timer = rate;

      if (!silence) {
        final diff = shiftRegister.bit(1) == 1 ? 2 : -2;

        level = (level + diff).clamp(0, 127);
      }

      shiftRegister >>= 1;
      bitsRemaining--;

      if (bitsRemaining == 0) {
        if (!sampleLoaded) {
          silence = true;
        } else {
          silence = false;
          shiftRegister = buffer;
          sampleLoaded = false;

          _startDma();
        }
      }
    }
  }

  void start() {
    address = sampleAddress;
    length = sampleLength;
  }

  int get output => level;

  int get status => length > 0 ? 1 : 0;

  int get interruptStatus => interrupt ? 1 : 0;

  void writeStatus(Bus bus, int value) {
    enabled = value.bit(4) == 1;
    interrupt = false;

    if (enabled) {
      if (length == 0) {
        length = sampleLength;
        address = sampleAddress;
      }
    } else {
      sampleLength = 0;
    }
  }

  void writeControl(int value) {
    irqEnabled = value.bit(7) == 1;
    loop = value.bit(6) == 1;
    rate = dmcTable[value & 0x0f];

    if (!irqEnabled) {
      interrupt = false;
    }
  }

  void writeDirectLoad(int value) {
    level = value & 0x7f;
  }

  void writeSampleAddress(int value) {
    sampleAddress = 0xC000 | (value << 6);
  }

  void writeSampleLength(int value) {
    sampleLength = (value << 4) + 1;
  }

  void writeDma(int value) {
    if (length == 0) {
      return;
    }

    buffer = value;
    sampleLoaded = true;

    address = 0x8000 | (address + 1) & 0x7fff;

    length--;

    if (length == 0) {
      if (loop) {
        start();
      } else if (irqEnabled) {
        interrupt = true;
      }
    }
  }

  void _startDma() {
    if (sampleLoaded || length == 0) {
      return;
    }

    startDma = true;
  }
}
