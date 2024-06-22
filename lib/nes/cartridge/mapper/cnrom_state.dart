import 'package:nes/nes/cartridge/mapper/mapper_state.dart';

class CNROMState extends MapperState {
  const CNROMState({
    required this.chrBank,
    super.id = 3,
  });

  const CNROMState.dummy() : this(chrBank: 0);

  final int chrBank;
}
