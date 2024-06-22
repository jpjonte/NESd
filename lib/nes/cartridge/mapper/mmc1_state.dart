import 'package:nes/nes/cartridge/mapper/mapper_state.dart';

class MMC1State extends MapperState {
  const MMC1State({
    required this.shift,
    required this.control,
    required this.chrBank0,
    required this.chrBank1,
    required this.prgBank,
    super.id = 1,
  });

  const MMC1State.dummy()
      : this(
          shift: 0,
          control: 0,
          chrBank0: 0,
          chrBank1: 0,
          prgBank: 0,
        );

  final int shift;

  final int control;

  final int chrBank0;
  final int chrBank1;

  final int prgBank;
}
