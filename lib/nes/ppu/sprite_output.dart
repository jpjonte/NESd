import 'package:binarize/binarize.dart';

class SpriteOutput {
  int patternLow = 0;
  int patternHigh = 0;

  int attribute = 0;

  int x = 0;

  SpriteOutputState get state => SpriteOutputState(
        patternLow: patternLow,
        patternHigh: patternHigh,
        attribute: attribute,
        x: x,
      );

  set state(SpriteOutputState state) {
    patternLow = state.patternLow;
    patternHigh = state.patternHigh;
    attribute = state.attribute;
    x = state.x;
  }
}

class SpriteOutputState {
  const SpriteOutputState({
    required this.patternLow,
    required this.patternHigh,
    required this.attribute,
    required this.x,
  });

  final int patternLow;
  final int patternHigh;

  final int attribute;

  final int x;
}

class _SpriteOutputStateContract extends BinaryContract<SpriteOutputState>
    implements SpriteOutputState {
  const _SpriteOutputStateContract()
      : super(
          const SpriteOutputState(
            patternLow: 0,
            patternHigh: 0,
            attribute: 0,
            x: 0,
          ),
        );

  @override
  SpriteOutputState order(SpriteOutputState contract) {
    return SpriteOutputState(
      patternLow: contract.patternLow,
      patternHigh: contract.patternHigh,
      attribute: contract.attribute,
      x: contract.x,
    );
  }

  @override
  int get patternLow => type(uint8, (o) => o.patternLow);

  @override
  int get patternHigh => type(uint8, (o) => o.patternHigh);

  @override
  int get attribute => type(uint8, (o) => o.attribute);

  @override
  int get x => type(uint8, (o) => o.x);
}

const spriteOutputStateContract = _SpriteOutputStateContract();
