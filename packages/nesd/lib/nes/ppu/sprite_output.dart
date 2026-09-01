import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';

class SpriteOutput {
  int patternLow = 0;
  int patternHigh = 0;

  int patternLow2 = 0;
  int patternHigh2 = 0;

  int attribute = 0;

  int x = 0;

  SpriteOutputState get state => SpriteOutputState(
    patternLow: patternLow,
    patternHigh: patternHigh,
    patternLow2: patternLow2,
    patternHigh2: patternHigh2,
    attribute: attribute,
    x: x,
  );

  set state(SpriteOutputState state) {
    patternLow = state.patternLow;
    patternHigh = state.patternHigh;
    patternLow2 = state.patternLow2;
    patternHigh2 = state.patternHigh2;
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
    this.patternLow2 = 0,
    this.patternHigh2 = 0,
  });

  factory SpriteOutputState.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => SpriteOutputState._version0(reader),
      1 => SpriteOutputState._version1(reader),
      _ => throw InvalidSerializationVersion('SpriteOutputState', version),
    };
  }

  factory SpriteOutputState._version0(PayloadReader reader) {
    return SpriteOutputState(
      patternLow: reader.get(uint8),
      patternHigh: reader.get(uint8),
      attribute: reader.get(uint8),
      x: reader.get(uint8),
    );
  }

  factory SpriteOutputState._version1(PayloadReader reader) {
    return SpriteOutputState(
      patternLow: reader.get(uint8),
      patternHigh: reader.get(uint8),
      patternLow2: reader.get(uint8),
      patternHigh2: reader.get(uint8),
      attribute: reader.get(uint8),
      x: reader.get(uint8),
    );
  }

  static List<SpriteOutputState> deserializeList(PayloadReader reader) {
    final length = reader.get(uint8);

    return List.generate(length, (_) => SpriteOutputState.deserialize(reader));
  }

  static void serializeList(
    PayloadWriter writer,
    List<SpriteOutputState> states,
  ) {
    writer.set(uint8, states.length);

    for (final state in states) {
      state.serialize(writer);
    }
  }

  final int patternLow;
  final int patternHigh;

  final int patternLow2;
  final int patternHigh2;

  final int attribute;

  final int x;

  void serialize(PayloadWriter writer) {
    writer
      ..set(uint8, 1) // version
      ..set(uint8, patternLow)
      ..set(uint8, patternHigh)
      ..set(uint8, patternLow2)
      ..set(uint8, patternHigh2)
      ..set(uint8, attribute)
      ..set(uint8, x);
  }
}
