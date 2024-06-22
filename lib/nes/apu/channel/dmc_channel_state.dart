import 'package:binarize/binarize.dart';

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
}

class _DMCChannelStateContract extends BinaryContract<DMCChannelState>
    implements DMCChannelState {
  const _DMCChannelStateContract() : super(const DMCChannelState.dummy());

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
}

const dmcChannelStateContract = _DMCChannelStateContract();
