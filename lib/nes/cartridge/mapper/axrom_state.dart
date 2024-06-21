import 'package:nes/nes/cartridge/mapper/mapper_state.dart';

class AXROMState extends MapperState {
  const AXROMState({
    required this.prgBank,
    required this.chrBank,
    super.id = 7,
  });

  const AXROMState.dummy()
      : this(
          prgBank: 0,
          chrBank: 0,
        );

  final int prgBank;

  final int chrBank;
}
