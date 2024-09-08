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
    try {
      return NESState.deserialize(Payload.read(bytes));
    } on InvalidSaveStateHeader {
      // fallback to old serialization
      return Payload.read(bytes).get(legacyNesStateContract);
    }
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

  NESState.dummy()
      : this(
          cpuState: CPUState.dummy(),
          ppuState: PPUState.dummy(),
          apuState: APUState.dummy(),
          cartridgeState: CartridgeState.dummy(),
          cycles: 0,
        );

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

class _LegacyNESStateContract extends BinaryContract<NESState>
    implements NESState {
  _LegacyNESStateContract() : super(NESState.dummy());

  @override
  NESState order(NESState contract) {
    return NESState(
      cpuState: contract.cpuState,
      ppuState: contract.ppuState,
      apuState: contract.apuState,
      cartridgeState: contract.cartridgeState,
      cycles: contract.cycles,
    );
  }

  @override
  CPUState get cpuState => type(legacyCpuStateContract, (o) => o.cpuState);

  @override
  PPUState get ppuState => type(legacyPpuStateContract, (o) => o.ppuState);

  @override
  APUState get apuState => type(legacyApuStateContract, (o) => o.apuState);

  @override
  CartridgeState get cartridgeState => type(
        legacyCartridgeStateContract,
        (o) => o.cartridgeState,
      );

  @override
  int get cycles => type(uint64, (o) => o.cycles);

  @override
  Uint8List serialize() => throw UnimplementedError();
}

final legacyNesStateContract = _LegacyNESStateContract();
