import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';
import 'package:nesd/nes/serialization/nesd_uint64.dart';

class VT02State extends MapperState {
  const VT02State({
    required super.id,
    required this.bank1,
    required this.timerPreload,
    required this.decodeControl,
    required this.scrollSelect,
    required this.programBanks,
    required this.bankControl,
    required this.ioControl,
    required this.ioData01,
    required this.ioData23,
    required this.rs232TimerLow,
    required this.rs232TimerHigh,
    required this.rs232Control,
    required this.rs232TxData,
    required this.dmaControl,
    required this.xop2,
    required this.extendedControl1,
    required this.extendedControl2,
    required this.videoBanks,
    required this.videoBank1,
    required this.videoBank0Select,
    required this.timerCounter,
    required this.timerRunning,
    required this.timerEnabled,
    required this.a12LowStart,
    required this.lastScanline,
  });

  factory VT02State.deserialize(PayloadReader reader, int id) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => VT02State._version0(reader, id),
      _ => throw InvalidSerializationVersion('VT02', version),
    };
  }

  factory VT02State._version0(PayloadReader reader, int id) {
    return VT02State(
      id: id,
      bank1: reader.get(uint8),
      timerPreload: reader.get(uint8),
      decodeControl: reader.get(uint8),
      scrollSelect: reader.get(uint8),
      programBanks: Uint8List.fromList(reader.get(list(uint8))),
      bankControl: reader.get(uint8),
      ioControl: reader.get(uint8),
      ioData01: reader.get(uint8),
      ioData23: reader.get(uint8),
      rs232TimerLow: reader.get(uint8),
      rs232TimerHigh: reader.get(uint8),
      rs232Control: reader.get(uint8),
      rs232TxData: reader.get(uint8),
      dmaControl: reader.get(uint8),
      xop2: reader.get(uint8),
      extendedControl1: reader.get(uint8),
      extendedControl2: reader.get(uint8),
      videoBanks: Uint8List.fromList(reader.get(list(uint8))),
      videoBank1: reader.get(uint8),
      videoBank0Select: reader.get(uint8),
      timerCounter: reader.get(uint8),
      timerRunning: reader.get(boolean),
      timerEnabled: reader.get(boolean),
      a12LowStart: reader.get(nesdUint64),
      lastScanline: reader.get(uint16),
    );
  }

  final int bank1;
  final int timerPreload;
  final int decodeControl;
  final int scrollSelect;
  final Uint8List programBanks;
  final int bankControl;

  final int ioControl;
  final int ioData01;
  final int ioData23;

  final int rs232TimerLow;
  final int rs232TimerHigh;
  final int rs232Control;
  final int rs232TxData;

  final int dmaControl;
  final int xop2;

  final int extendedControl1;
  final int extendedControl2;
  final Uint8List videoBanks;
  final int videoBank1;
  final int videoBank0Select;

  final int timerCounter;
  final bool timerRunning;
  final bool timerEnabled;

  final int a12LowStart;
  final int lastScanline;

  @override
  void serialize(PayloadWriter writer) {
    super.serialize(writer);

    writer
      ..set(uint8, 0) // version
      ..set(uint8, bank1)
      ..set(uint8, timerPreload)
      ..set(uint8, decodeControl)
      ..set(uint8, scrollSelect)
      ..set(list(uint8), programBanks)
      ..set(uint8, bankControl)
      ..set(uint8, ioControl)
      ..set(uint8, ioData01)
      ..set(uint8, ioData23)
      ..set(uint8, rs232TimerLow)
      ..set(uint8, rs232TimerHigh)
      ..set(uint8, rs232Control)
      ..set(uint8, rs232TxData)
      ..set(uint8, dmaControl)
      ..set(uint8, xop2)
      ..set(uint8, extendedControl1)
      ..set(uint8, extendedControl2)
      ..set(list(uint8), videoBanks)
      ..set(uint8, videoBank1)
      ..set(uint8, videoBank0Select)
      ..set(uint8, timerCounter)
      ..set(boolean, timerRunning)
      ..set(boolean, timerEnabled)
      ..set(nesdUint64, a12LowStart)
      ..set(uint16, lastScanline);
  }
}
