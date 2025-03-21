import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/apu/channel/dmc_channel_state.dart';
import 'package:nesd/nes/bus.dart';

const dmcTable = [
  428,
  380,
  340,
  320,
  286,
  254,
  226,
  214,
  190,
  160,
  142,
  128,
  106,
  84,
  72,
  54,
];

class DMCChannel {
  bool enabled = false;

  bool irqEnabled = false;
  bool interrupt = false;
  bool loop = false;
  bool silence = false;

  int buffer = 0;
  int rate = 0;

  int bitsRemaining = 8;
  int shiftRegister = 0;

  int timer = 0;

  int level = 0;

  int sampleAddress = 0;
  int sampleLength = 0;

  int address = 0;
  int length = 0;

  bool sampleLoaded = false;

  bool startDma = false;

  DMCChannelState get state => DMCChannelState(
    enabled: enabled,
    irqEnabled: irqEnabled,
    interrupt: interrupt,
    loop: loop,
    silence: silence,
    buffer: buffer,
    rate: rate,
    bitsRemaining: bitsRemaining,
    shiftRegister: shiftRegister,
    timer: timer,
    level: level,
    sampleAddress: sampleAddress,
    sampleLength: sampleLength,
    address: address,
    currentLength: length,
    sampleLoaded: sampleLoaded,
    startDma: startDma,
  );

  set state(DMCChannelState value) {
    enabled = value.enabled;
    irqEnabled = value.irqEnabled;
    interrupt = value.interrupt;
    loop = value.loop;
    silence = value.silence;
    buffer = value.buffer;
    rate = value.rate;
    bitsRemaining = value.bitsRemaining;
    shiftRegister = value.shiftRegister;
    timer = value.timer;
    level = value.level;
    sampleAddress = value.sampleAddress;
    sampleLength = value.sampleLength;
    address = value.address;
    length = value.currentLength;
    sampleLoaded = value.sampleLoaded;
    startDma = value.startDma;
  }

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
    bitsRemaining = 8;
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
        final diff = shiftRegister.bit(0) == 1 ? 2 : -2;

        level = (level + diff).clamp(0, 0x7f);
        shiftRegister >>= 1;
      }

      bitsRemaining--;

      if (bitsRemaining == 0) {
        bitsRemaining = 8;

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

  void _start() {
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
        _start();
        _startDma();
      }
    } else {
      length = 0;
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
        _start();
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
