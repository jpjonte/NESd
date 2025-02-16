import 'package:binarize/binarize.dart';
import 'package:collection/collection.dart';
import 'package:nesd/exception/invalid_save_state_header.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/apu/apu_state.dart';
import 'package:nesd/nes/cartridge/cartridge_state.dart';
import 'package:nesd/nes/cpu/cpu_state.dart';
import 'package:nesd/nes/ppu/ppu_state.dart';

class NESState {
  static const headerBytes = [0x4e, 0x45, 0x53, 0x64]; // "NESd"

  const NESState({
    required this.cpuState,
    required this.ppuState,
    required this.apuState,
    required this.cartridgeState,
    required this.cycles,
  });

  factory NESState.fromBytes(Uint8List bytes) {
    return NESState.deserialize(Payload.read(bytes));
  }

  factory NESState.deserialize(PayloadReader reader) {
    final header = reader.get(const Bytes(4));

    if (!const ListEquality().equals(header, headerBytes)) {
      throw InvalidSaveStateHeader(header);
    }

    final version = reader.get(uint8);

    if (version != 0) {
      throw InvalidSerializationVersion('Save State', version);
    }

    final consoleType = reader.get(uint8);

    if (consoleType != 0) {
      throw InvalidSerializationVersion('Console Type', consoleType);
    }

    final nesStateVersion = reader.get(uint8);

    return switch (nesStateVersion) {
      0 => NESState._version0(reader),
      _ => throw InvalidSerializationVersion('NESState', nesStateVersion),
    };
  }

  factory NESState._version0(PayloadReader reader) {
    return NESState(
      cpuState: CPUState.deserialize(reader),
      ppuState: PPUState.deserialize(reader),
      apuState: APUState.deserialize(reader),
      cartridgeState: CartridgeState.deserialize(reader),
      cycles: reader.get(uint64),
    );
  }

  final CPUState cpuState;

  final PPUState ppuState;

  final APUState apuState;

  final CartridgeState cartridgeState;

  final int cycles;

  Uint8List serialize() {
    final writer = Payload.write()
          ..set(const Bytes(4), headerBytes)
          ..set(uint8, 0) // save state version
          ..set(uint8, 0) // console type
          ..set(uint8, 0) // NESState version
        ;

    cpuState.serialize(writer);
    ppuState.serialize(writer);
    apuState.serialize(writer);
    cartridgeState.serialize(writer);

    writer.set(uint64, cycles);

    return binarize(writer);
  }
}
