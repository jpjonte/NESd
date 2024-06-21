import 'package:binarize/binarize.dart';
import 'package:nes/nes/apu/apu_state.dart';
import 'package:nes/nes/cartridge/cartridge_state.dart';
import 'package:nes/nes/cpu/cpu_state.dart';
import 'package:nes/nes/ppu/ppu_state.dart';

class NESState {
  const NESState({
    required this.cpuState,
    required this.ppuState,
    required this.apuState,
    required this.cartridgeState,
    required this.cycles,
  });

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
}

class _NESStateContract extends BinaryContract<NESState> implements NESState {
  _NESStateContract() : super(NESState.dummy());

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
  CPUState get cpuState => type(cpuStateContract, (o) => o.cpuState);

  @override
  PPUState get ppuState => type(ppuStateContract, (o) => o.ppuState);

  @override
  APUState get apuState => type(apuStateContract, (o) => o.apuState);

  @override
  CartridgeState get cartridgeState => type(
        cartridgeStateContract,
        (o) => o.cartridgeState,
      );

  @override
  int get cycles => type(uint64, (o) => o.cycles);
}

final nesStateContract = _NESStateContract();
