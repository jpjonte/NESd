import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/mapper/bandai_fcg_state.dart';
import 'package:nesd/nes/cartridge/mapper/chip/eeprom_24c02.dart';
import 'package:nesd/nes/cartridge/mapper/chip/eeprom_24c02_state.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

BandaiFCGState _buildState({Eeprom24C02State? eeprom}) => BandaiFCGState(
  chrPages: const [7, 6, 5, 4, 3, 2, 1, 0],
  prgPage: 3,
  nametableLayout: NametableLayout.singleUpper,
  irqEnabled: true,
  irqCounter: 0x1234,
  irqLatch: 0xabcd,
  eeprom: eeprom,
);

Eeprom24C02State _buildEepromState() => Eeprom24C02State(
  previousScl: 1,
  previousSda: 0,
  address: 0x21,
  bit: 3,
  control: 0xa0,
  shift: 0x55,
  flush: true,
  mode: Eeprom24C02Mode.write,
  buffer: Uint8List.fromList(List.generate(16, (i) => i)),
  data: Uint8List.fromList(List.generate(256, (i) => (i * 3) & 0xff)),
  output: 0,
);

void _expectStatesEqual(BandaiFCGState actual, BandaiFCGState expected) {
  expect(actual.chrPages, expected.chrPages);
  expect(actual.prgPage, expected.prgPage);
  expect(actual.nametableLayout, expected.nametableLayout);
  expect(actual.irqEnabled, expected.irqEnabled);
  expect(actual.irqCounter, expected.irqCounter);
  expect(actual.irqLatch, expected.irqLatch);

  final actualEeprom = actual.eeprom;
  final expectedEeprom = expected.eeprom;

  if (expectedEeprom == null) {
    expect(actualEeprom, isNull);

    return;
  }

  expect(actualEeprom, isNotNull);
  expect(actualEeprom!.previousScl, expectedEeprom.previousScl);
  expect(actualEeprom.previousSda, expectedEeprom.previousSda);
  expect(actualEeprom.address, expectedEeprom.address);
  expect(actualEeprom.bit, expectedEeprom.bit);
  expect(actualEeprom.control, expectedEeprom.control);
  expect(actualEeprom.shift, expectedEeprom.shift);
  expect(actualEeprom.flush, expectedEeprom.flush);
  expect(actualEeprom.mode, expectedEeprom.mode);
  expect(actualEeprom.buffer, expectedEeprom.buffer);
  expect(actualEeprom.data, expectedEeprom.data);
  expect(actualEeprom.output, expectedEeprom.output);
}

void main() {
  test('round-trips without an EEPROM', () {
    final original = _buildState();

    final writer = Payload.write();

    original.serialize(writer);

    final bytes = binarize(writer);

    expect(bytes[0], 0, reason: 'MapperState envelope version');
    expect(bytes[1], 16, reason: 'mapper id');
    expect(bytes[2], 0, reason: 'BandaiFCGState version');

    final decoded =
        MapperState.deserialize(Payload.read(bytes)) as BandaiFCGState;

    _expectStatesEqual(decoded, original);
  });

  test('round-trips with an EEPROM', () {
    final original = _buildState(eeprom: _buildEepromState());

    final writer = Payload.write();

    original.serialize(writer);

    final decoded =
        MapperState.deserialize(Payload.read(binarize(writer)))
            as BandaiFCGState;

    _expectStatesEqual(decoded, original);
  });
}
