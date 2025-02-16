import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';

class DMCChannelState {
  const DMCChannelState({
    required this.enabled,
    required this.irqEnabled,
    required this.interrupt,
    required this.loop,
    required this.silence,
    required this.buffer,
    required this.rate,
    required this.bitsRemaining,
    required this.shiftRegister,
    required this.timer,
    required this.level,
    required this.sampleAddress,
    required this.sampleLength,
    required this.address,
    required this.currentLength,
    required this.sampleLoaded,
    required this.startDma,
  });

  factory DMCChannelState.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => DMCChannelState._version0(reader),
      _ => throw InvalidSerializationVersion('DMCChannelState', version),
    };
  }

  factory DMCChannelState._version0(PayloadReader reader) {
    return DMCChannelState(
      enabled: reader.get(boolean),
      irqEnabled: reader.get(boolean),
      interrupt: reader.get(boolean),
      loop: reader.get(boolean),
      silence: reader.get(boolean),
      buffer: reader.get(uint8),
      rate: reader.get(uint8),
      bitsRemaining: reader.get(uint8),
      shiftRegister: reader.get(uint8),
      timer: reader.get(uint8),
      level: reader.get(uint8),
      sampleAddress: reader.get(uint16),
      sampleLength: reader.get(uint16),
      address: reader.get(uint16),
      currentLength: reader.get(uint16),
      sampleLoaded: reader.get(boolean),
      startDma: reader.get(boolean),
    );
  }

  final bool enabled;

  final bool irqEnabled;
  final bool interrupt;
  final bool loop;
  final bool silence;

  final int buffer;
  final int rate;

  final int bitsRemaining;
  final int shiftRegister;

  final int timer;

  final int level;

  final int sampleAddress;
  final int sampleLength;

  final int address;
  final int currentLength;

  final bool sampleLoaded;

  final bool startDma;

  void serialize(PayloadWriter writer) {
    writer
      ..set(uint8, 0) // version
      ..set(boolean, enabled)
      ..set(boolean, irqEnabled)
      ..set(boolean, interrupt)
      ..set(boolean, loop)
      ..set(boolean, silence)
      ..set(uint8, buffer)
      ..set(uint8, rate)
      ..set(uint8, bitsRemaining)
      ..set(uint8, shiftRegister)
      ..set(uint8, timer)
      ..set(uint8, level)
      ..set(uint16, sampleAddress)
      ..set(uint16, sampleLength)
      ..set(uint16, address)
      ..set(uint16, currentLength)
      ..set(boolean, sampleLoaded)
      ..set(boolean, startDma);
  }
}
