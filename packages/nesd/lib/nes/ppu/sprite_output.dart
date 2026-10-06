import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';

class SpriteOutput {
  int patternLow = 0;
  int patternHigh = 0;

  int patternLow2 = 0;
  int patternHigh2 = 0;

  int attribute = 0;

  int x = 0;

  /// Dots left before the sprite starts shifting out; loaded from [x].
  int counter = 0;

  /// Pixels already shifted out of [pixels].
  int shifted = 0;

  /// The loaded pixels in output order, as sprite line entries; only
  /// meaningful while [opaque].
  final Uint8List pixels = Uint8List(16);

  int width = 8;

  bool opaque = false;

  SpriteOutputState get state => SpriteOutputState(
    patternLow: patternLow,
    patternHigh: patternHigh,
    patternLow2: patternLow2,
    patternHigh2: patternHigh2,
    attribute: attribute,
    x: x,
    counter: counter,
    shifted: shifted,
  );

  set state(SpriteOutputState state) {
    patternLow = state.patternLow;
    patternHigh = state.patternHigh;
    patternLow2 = state.patternLow2;
    patternHigh2 = state.patternHigh2;
    attribute = state.attribute;
    x = state.x;
    counter = state.counter ?? state.x;
    shifted = state.shifted ?? 0;
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
    this.counter,
    this.shifted,
  });

  factory SpriteOutputState.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => SpriteOutputState._version0(reader),
      1 => SpriteOutputState._version1(reader),
      2 => SpriteOutputState._version2(reader),
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

  factory SpriteOutputState._version2(PayloadReader reader) {
    return SpriteOutputState(
      patternLow: reader.get(uint8),
      patternHigh: reader.get(uint8),
      patternLow2: reader.get(uint8),
      patternHigh2: reader.get(uint8),
      attribute: reader.get(uint8),
      x: reader.get(uint8),
      counter: reader.get(uint8),
      shifted: reader.get(uint8),
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

  /// Null in states saved before the counters ran per dot.
  final int? counter;
  final int? shifted;

  void serialize(PayloadWriter writer) {
    writer
      ..set(uint8, 2) // version
      ..set(uint8, patternLow)
      ..set(uint8, patternHigh)
      ..set(uint8, patternLow2)
      ..set(uint8, patternHigh2)
      ..set(uint8, attribute)
      ..set(uint8, x)
      ..set(uint8, counter ?? x)
      ..set(uint8, shifted ?? 0);
  }
}
