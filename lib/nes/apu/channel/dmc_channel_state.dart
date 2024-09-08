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

  const DMCChannelState.dummy()
      : enabled = false,
        irqEnabled = false,
        interrupt = false,
        loop = false,
        silence = false,
        buffer = 0,
        rate = 0,
        bitsRemaining = 8,
        shiftRegister = 0,
        timer = 0,
        level = 0,
        sampleAddress = 0,
        sampleLength = 0,
        address = 0,
        currentLength = 0,
        sampleLoaded = false,
        startDma = false;

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

class _LegacyDMCChannelStateContract extends BinaryContract<DMCChannelState>
    implements DMCChannelState {
  const _LegacyDMCChannelStateContract() : super(const DMCChannelState.dummy());

  @override
  DMCChannelState order(DMCChannelState contract) {
    return DMCChannelState(
      enabled: contract.enabled,
      irqEnabled: contract.irqEnabled,
      interrupt: contract.interrupt,
      loop: contract.loop,
      silence: contract.silence,
      buffer: contract.buffer,
      rate: contract.rate,
      bitsRemaining: contract.bitsRemaining,
      shiftRegister: contract.shiftRegister,
      timer: contract.timer,
      level: contract.level,
      sampleAddress: contract.sampleAddress,
      sampleLength: contract.sampleLength,
      address: contract.address,
      currentLength: contract.currentLength,
      sampleLoaded: contract.sampleLoaded,
      startDma: contract.startDma,
    );
  }

  @override
  bool get enabled => type(boolean, (o) => o.enabled);

  @override
  bool get irqEnabled => type(boolean, (o) => o.irqEnabled);

  @override
  bool get interrupt => type(boolean, (o) => o.interrupt);

  @override
  bool get loop => type(boolean, (o) => o.loop);

  @override
  bool get silence => type(boolean, (o) => o.silence);

  @override
  int get buffer => type(uint8, (o) => o.buffer);

  @override
  int get rate => type(uint8, (o) => o.rate);

  @override
  int get bitsRemaining => type(uint8, (o) => o.bitsRemaining);

  @override
  int get shiftRegister => type(uint8, (o) => o.shiftRegister);

  @override
  int get timer => type(uint8, (o) => o.timer);

  @override
  int get level => type(uint8, (o) => o.level);

  @override
  int get sampleAddress => type(uint16, (o) => o.sampleAddress);

  @override
  int get sampleLength => type(uint16, (o) => o.sampleLength);

  @override
  int get address => type(uint16, (o) => o.address);

  @override
  int get currentLength => type(uint16, (o) => o.currentLength);

  @override
  bool get sampleLoaded => type(boolean, (o) => o.sampleLoaded);

  @override
  bool get startDma => type(boolean, (o) => o.startDma);

  @override
  void serialize(PayloadWriter writer) => throw UnimplementedError();
}

const legacyDmcChannelStateContract = _LegacyDMCChannelStateContract();
