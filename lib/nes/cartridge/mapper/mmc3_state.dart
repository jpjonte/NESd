import 'package:nes/nes/cartridge/mapper/mapper_state.dart';

class MMC3State extends MapperState {
  const MMC3State({
    required this.register,
    required this.r0,
    required this.r1,
    required this.r2,
    required this.r3,
    required this.r4,
    required this.r5,
    required this.r6,
    required this.r7,
    required this.prgBankMode,
    required this.chrBankMode,
    required this.mirroring,
    required this.irqCounter,
    required this.irqLatch,
    required this.irqReload,
    required this.irqEnabled,
    required this.a12LowStart,
    super.id = 4,
  });

  const MMC3State.dummy()
      : this(
          register: 0,
          r0: 0,
          r1: 0,
          r2: 0,
          r3: 0,
          r4: 0,
          r5: 0,
          r6: 0,
          r7: 0,
          prgBankMode: 0,
          chrBankMode: 0,
          mirroring: 0,
          irqCounter: 0,
          irqLatch: 0,
          irqReload: false,
          irqEnabled: false,
          a12LowStart: null,
        );

  final int register;
  final int r0;
  final int r1;
  final int r2;
  final int r3;
  final int r4;
  final int r5;
  final int r6;
  final int r7;

  final int prgBankMode;

  final int chrBankMode;

  final int mirroring;

  final int irqCounter;
  final int irqLatch;

  final bool irqReload;
  final bool irqEnabled;

  final int? a12LowStart;
}
