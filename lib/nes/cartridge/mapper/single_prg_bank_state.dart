import 'package:nes/nes/cartridge/mapper/mapper_state.dart';

class SinglePrgBankState extends MapperState {
  const SinglePrgBankState({
    required super.id,
    required this.prgBank,
  });

  const SinglePrgBankState.dummy() : this(id: 0, prgBank: 0);

  final int prgBank;
}
