import 'dart:typed_data';

import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/apu/expansion/expansion_audio.dart';
import 'package:nesd/nes/apu/expansion/namco163_audio_state.dart';
import 'package:nesd/nes/apu/tables.dart';

class Namco163Audio implements ExpansionAudio {
  Namco163Audio(this.subMapperId) : _scale = n163ScaleFor(subMapperId);

  final int subMapperId;

  final double _scale;

  final Uint8List ram = Uint8List(0x80);

  int address = 0;

  bool autoIncrement = false;

  int slotTimer = n163SlotCycles;

  int slot = 0;

  final Int8List channelOutput = Int8List(8);

  bool soundDisabled = false;

  final List<int> _debugOutputs = List.filled(8, n163DebugBias);

  Namco163AudioState get state => Namco163AudioState(
    ram: Uint8List.fromList(ram),
    channelOutput: Int8List.fromList(channelOutput),
    address: address,
    autoIncrement: autoIncrement,
    soundDisabled: soundDisabled,
    slotTimer: slotTimer,
    slot: slot,
  );

  set state(Namco163AudioState state) {
    ram.setAll(0, state.ram);
    channelOutput.setAll(0, state.channelOutput);

    address = state.address;
    autoIncrement = state.autoIncrement;
    soundDisabled = state.soundDisabled;

    slotTimer = state.slotTimer;
    slot = state.slot;
  }

  @override
  ExpansionAudioKind get kind => ExpansionAudioKind.namco163;

  @override
  double get output => soundDisabled ? 0.0 : channelOutput[7 - slot] * _scale;

  @override
  List<int> get debugOutputs {
    for (var i = 0; i < _debugOutputs.length; i++) {
      _debugOutputs[i] = channelOutput[i] + n163DebugBias;
    }

    return _debugOutputs;
  }

  int get enabledChannels => ((ram[0x7f] >> 4) & 7) + 1;

  int volumeOf(int index) => ram[0x40 + index * 8 + 7] & 0x0f;

  int waveLengthOf(int index) => 256 - (ram[0x40 + index * 8 + 4] & 0xfc);

  int frequencyOf(int index) {
    final base = 0x40 + index * 8;

    return ((ram[base + 4] & 0x03) << 16) | (ram[base + 2] << 8) | ram[base];
  }

  void writeAddress(int value) {
    address = value & 0x7f;
    autoIncrement = value.bit(7) == 1;
  }

  void writeData(int value) {
    ram[address] = value;

    _advance();
  }

  int readData({bool disableSideEffects = false}) {
    final value = ram[address];

    if (!disableSideEffects) {
      _advance();
    }

    return value;
  }

  void reset() {
    ram.fillRange(0, ram.length, 0);
    channelOutput.fillRange(0, channelOutput.length, 0);

    address = 0;
    autoIncrement = false;

    slotTimer = n163SlotCycles;
    slot = 0;

    soundDisabled = false;
  }

  /// Auto-increment stops at `0x7f` instead of wrapping to `0x00`.
  void _advance() {
    if (autoIncrement && address < 0x7f) {
      address++;
    }
  }

  @override
  @pragma('vm:prefer-inline')
  void step() {
    if (--slotTimer > 0) {
      return;
    }

    slotTimer = n163SlotCycles;

    final next = slot + 1;

    slot = next >= enabledChannels ? 0 : next;

    _updateChannel(7 - slot);
  }

  void _updateChannel(int index) {
    final base = 0x40 + index * 8;

    final frequency = frequencyOf(index);
    final length = waveLengthOf(index);

    final previous =
        (ram[base + 5] << 16) | (ram[base + 3] << 8) | ram[base + 1];

    final phase = (previous + frequency) % (length << 16);

    ram[base + 1] = phase & 0xff;
    ram[base + 3] = (phase >> 8) & 0xff;
    ram[base + 5] = (phase >> 16) & 0xff;

    final sampleIndex = ((phase >> 16) + ram[base + 6]) & 0xff;
    final sample = (ram[sampleIndex >> 1] >> ((sampleIndex & 1) * 4)) & 0x0f;

    channelOutput[index] = (sample - 8) * volumeOf(index);
  }
}
