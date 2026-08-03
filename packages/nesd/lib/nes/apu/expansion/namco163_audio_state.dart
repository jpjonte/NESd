import 'dart:typed_data';

import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/apu/tables.dart';

class Namco163AudioState {
  const Namco163AudioState({
    required this.ram,
    required this.channelOutput,
    required this.address,
    required this.autoIncrement,
    required this.soundDisabled,
    required this.slotTimer,
    required this.slot,
  });

  Namco163AudioState.initial()
    : ram = Uint8List(0x80),
      channelOutput = Int8List(8),
      address = 0,
      autoIncrement = false,
      soundDisabled = false,
      slotTimer = n163SlotCycles,
      slot = 0;

  factory Namco163AudioState.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => Namco163AudioState._version0(reader),
      _ => throw InvalidSerializationVersion('Namco163AudioState', version),
    };
  }

  factory Namco163AudioState._version0(PayloadReader reader) {
    return Namco163AudioState(
      ram: Uint8List.fromList(reader.get(list(uint8))),
      channelOutput: Int8List.fromList(reader.get(list(int8))),
      address: reader.get(uint8),
      autoIncrement: reader.get(boolean),
      soundDisabled: reader.get(boolean),
      slotTimer: reader.get(uint8),
      slot: reader.get(uint8),
    );
  }

  final Uint8List ram;

  final Int8List channelOutput;

  final int address;
  final bool autoIncrement;
  final bool soundDisabled;

  final int slotTimer;
  final int slot;

  void serialize(PayloadWriter writer) {
    writer
      ..set(uint8, 0) // version
      ..set(list(uint8), ram)
      ..set(list(int8), channelOutput)
      ..set(uint8, address)
      ..set(boolean, autoIncrement)
      ..set(boolean, soundDisabled)
      ..set(uint8, slotTimer)
      ..set(uint8, slot);
  }
}
