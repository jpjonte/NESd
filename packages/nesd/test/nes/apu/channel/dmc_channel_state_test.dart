import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/apu/channel/dmc_channel_state.dart';

DMCChannelState buildState({int rate = 428, int timer = 428}) {
  return DMCChannelState(
    enabled: true,
    irqEnabled: true,
    interrupt: false,
    loop: true,
    silence: false,
    buffer: 0xba,
    rate: rate,
    bitsRemaining: 5,
    shiftRegister: 0x6c,
    timer: timer,
    level: 0x45,
    sampleAddress: 0xffc0,
    sampleLength: 4081,
    address: 0xfedc,
    currentLength: 1234,
    sampleLoaded: true,
    startDma: false,
  );
}

void expectStatesEqual(DMCChannelState actual, DMCChannelState expected) {
  expect(actual.enabled, expected.enabled);
  expect(actual.irqEnabled, expected.irqEnabled);
  expect(actual.interrupt, expected.interrupt);
  expect(actual.loop, expected.loop);
  expect(actual.silence, expected.silence);
  expect(actual.buffer, expected.buffer);
  expect(actual.rate, expected.rate);
  expect(actual.bitsRemaining, expected.bitsRemaining);
  expect(actual.shiftRegister, expected.shiftRegister);
  expect(actual.timer, expected.timer);
  expect(actual.level, expected.level);
  expect(actual.sampleAddress, expected.sampleAddress);
  expect(actual.sampleLength, expected.sampleLength);
  expect(actual.address, expected.address);
  expect(actual.currentLength, expected.currentLength);
  expect(actual.sampleLoaded, expected.sampleLoaded);
  expect(actual.startDma, expected.startDma);
}

void main() {
  test('serialize writes version 1 and round-trips slow DMC rates', () {
    final original = buildState();

    final writer = Payload.write();
    original.serialize(writer);
    final bytes = binarize(writer);

    expect(bytes[0], 1, reason: 'DMCChannelState version');

    final decoded = DMCChannelState.deserialize(Payload.read(bytes));

    expectStatesEqual(decoded, original);
  });

  test('still reads legacy version 0 payloads', () {
    final original = buildState(rate: 214, timer: 100);

    // replicate the exact v0 wire format the previous code produced
    final writer = Payload.write()
      ..set(uint8, 0)
      ..set(boolean, original.enabled)
      ..set(boolean, original.irqEnabled)
      ..set(boolean, original.interrupt)
      ..set(boolean, original.loop)
      ..set(boolean, original.silence)
      ..set(uint8, original.buffer)
      ..set(uint8, original.rate)
      ..set(uint8, original.bitsRemaining)
      ..set(uint8, original.shiftRegister)
      ..set(uint8, original.timer)
      ..set(uint8, original.level)
      ..set(uint16, original.sampleAddress)
      ..set(uint16, original.sampleLength)
      ..set(uint16, original.address)
      ..set(uint16, original.currentLength)
      ..set(boolean, original.sampleLoaded)
      ..set(boolean, original.startDma);

    final decoded = DMCChannelState.deserialize(Payload.read(binarize(writer)));

    expectStatesEqual(decoded, original);
  });
}
