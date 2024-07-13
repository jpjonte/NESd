import 'package:binarize/binarize.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';
import 'package:nesd/nes/cartridge/mapper/nrom_state.dart';

class CartridgeState {
  const CartridgeState({
    required this.chr,
    required this.sram,
    required this.mapperId,
    required this.mapperState,
  });

  CartridgeState.dummy()
      : this(
          chr: Uint8List(1),
          sram: Uint8List(1),
          mapperId: 0,
          mapperState: const NROMState(),
        );

  final Uint8List chr;

  final Uint8List sram;

  final int mapperId;

  final MapperState mapperState;
}

class _CartridgeStateContract extends BinaryContract<CartridgeState>
    implements CartridgeState {
  _CartridgeStateContract() : super(CartridgeState.dummy());

  @override
  CartridgeState order(CartridgeState contract) {
    return CartridgeState(
      chr: contract.chr,
      sram: contract.sram,
      mapperId: contract.mapperId,
      mapperState: contract.mapperState,
    );
  }

  @override
  Uint8List get chr => Uint8List.fromList(type(list(uint8), (o) => o.chr));

  @override
  Uint8List get sram => Uint8List.fromList(type(list(uint8), (o) => o.sram));

  @override
  int get mapperId => type(uint8, (o) => o.mapperId);

  @override
  MapperState get mapperState => type(mapperStateType, (o) => o.mapperState);
}

final cartridgeStateContract = _CartridgeStateContract();
