import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';

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

  factory SpriteOutputState.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => SpriteOutputState._version0(reader),
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

  final int attribute;

  final int x;

  void serialize(PayloadWriter writer) {
    writer
      ..set(uint8, 0) // version
      ..set(uint8, patternLow)
      ..set(uint8, patternHigh)
      ..set(uint8, attribute)
      ..set(uint8, x);
  }
}
