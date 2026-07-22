import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/debugger/execution_log.dart';
import 'package:nesd/nes/debugger/execution_log_state.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/isolate/nes_isolate.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/ui/emulator/cartridge_info.dart';
import 'package:nesd/ui/emulator/remote_nes.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

/// Minimal fake mirroring `_FakeNesIsolateHandle` in `remote_nes_test.dart`
/// and `debugger_client_test.dart`: records sent commands and lets the test
/// emit isolate events, so the real `RemoteNes` (and, in turn, the real
/// `ExecutionLog` under test) run against a controllable double instead of
/// a spawned isolate.
class _FakeNesIsolateHandle implements NesIsolateHandle {
  final StreamController<NesIsolateEvent> _controller =
      StreamController<NesIsolateEvent>.broadcast();

  final List<NesCommand> commands = [];

  @override
  Stream<NesIsolateEvent> get events => _controller.stream;

  @override
  void send(NesCommand command) => commands.add(command);

  void emit(NesIsolateEvent event) => _controller.add(event);

  @override
  Future<void> dispose() => _controller.close();
}

RomInfo _testRomInfo() => const RomInfo(
  file: FilesystemFile(
    path: 'test.nes',
    name: 'test.nes',
    type: FilesystemFileType.file,
  ),
);

CartridgeInfo _testCartridgeInfo() => const CartridgeInfo(
  filename: 'test.nes',
  romFormat: RomFormat.iNes,
  prgRomSize: 0,
  chrRomSize: 0,
  nametableLayout: NametableLayout.horizontal,
  alternativeNametableLayout: false,
  hasBattery: false,
  hasTrainer: false,
  consoleType: ConsoleType.nes,
  mapperName: 'NROM',
  mapperId: 0,
  subMapperId: 0,
  prgRamSize: 0,
  prgSaveRamSize: 0,
  tvSystem: TvSystem.ntsc,
);

ExecutionLogLine _line(int address) => ExecutionLogLine(
  address: address,
  opcode: 0xEA,
  operands: const [],
  instruction: 'NOP',
  disassembly: '',
  effectiveAddress: null,
  value: null,
  A: 0,
  X: 0,
  Y: 0,
  SP: 0xFD,
  P: 0x24,
  scanline: 0,
  cycle: 0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeNesIsolateHandle handle;
  late RemoteNes remote;
  late ProviderContainer container;
  late ExecutionLogStateNotifier notifier;

  setUp(() {
    handle = _FakeNesIsolateHandle();
    remote = RemoteNes(
      isolate: handle,
      romInfo: _testRomInfo(),
      fileHash: 'abc123',
      hasZapper: false,
      cartridgeInfo: _testCartridgeInfo(),
    );

    container = ProviderContainer();

    // `executionLogStateProvider` is autoDispose; listening (rather than a
    // one-off `read`) keeps the notifier instance the test holds onto
    // alive across this test's `pumpEventQueue` gaps.
    notifier = container
        .listen(executionLogStateProvider.notifier, (_, _) {})
        .read();
  });

  tearDown(() {
    remote.dispose();
    container.dispose();
  });

  test(
    'enable sends SetExecutionLogEnabledCommand(true) and flips notifier',
    () {
      final executionLog = ExecutionLog(nes: remote, notifier: notifier)
        ..enable();

      expect(notifier.executionLogState.enabled, isTrue);
      expect(
        handle.commands,
        contains(
          isA<SetExecutionLogEnabledCommand>().having(
            (c) => c.enabled,
            'enabled',
            isTrue,
          ),
        ),
      );

      executionLog.dispose();
    },
  );

  test(
    'disable sends SetExecutionLogEnabledCommand(false) and flips notifier',
    () {
      final executionLog = ExecutionLog(nes: remote, notifier: notifier)
        ..enable()
        ..disable();

      expect(notifier.executionLogState.enabled, isFalse);
      expect(
        handle.commands,
        contains(
          isA<SetExecutionLogEnabledCommand>().having(
            (c) => c.enabled,
            'enabled',
            isFalse,
          ),
        ),
      );

      executionLog.dispose();
    },
  );

  test('toggle flips between enable and disable', () {
    final executionLog = ExecutionLog(nes: remote, notifier: notifier)
      ..toggle();
    expect(notifier.executionLogState.enabled, isTrue);

    executionLog.toggle();
    expect(notifier.executionLogState.enabled, isFalse);

    executionLog.dispose();
  });

  test('ExecutionLogEvent lines are appended while enabled', () async {
    final executionLog = ExecutionLog(nes: remote, notifier: notifier)
      ..enable();

    handle.emit(ExecutionLogEvent(lines: [_line(0x8000), _line(0x8001)]));

    await pumpEventQueue();

    expect(executionLog.lines.map((l) => l.address), [0x8000, 0x8001]);
    expect(notifier.executionLogState.lines.map((l) => l.address), [
      0x8000,
      0x8001,
    ]);

    handle.emit(ExecutionLogEvent(lines: [_line(0x8002)]));

    await pumpEventQueue();

    expect(executionLog.lines.map((l) => l.address), [0x8000, 0x8001, 0x8002]);

    executionLog.dispose();
  });

  test('ExecutionLogEvent lines are ignored while disabled', () async {
    final executionLog = ExecutionLog(nes: remote, notifier: notifier);

    handle.emit(ExecutionLogEvent(lines: [_line(0x9000)]));

    await pumpEventQueue();

    expect(executionLog.lines, isEmpty);

    executionLog.dispose();
  });

  test('clear empties both the local buffer and the notifier', () async {
    final executionLog = ExecutionLog(nes: remote, notifier: notifier)
      ..enable();

    handle.emit(ExecutionLogEvent(lines: [_line(0xA000)]));

    await pumpEventQueue();

    expect(executionLog.lines, isNotEmpty);

    executionLog.clear();

    expect(executionLog.lines, isEmpty);
    expect(notifier.executionLogState.lines, isEmpty);

    executionLog.dispose();
  });

  test('printLine formats a canonical nestest-style line', () {
    final executionLog = ExecutionLog(nes: remote, notifier: notifier);

    final line = executionLog.printLine(
      const ExecutionLogLine(
        address: 0xC000,
        opcode: 0x4C,
        operands: [0x00, 0xC0],
        instruction: 'JMP',
        disassembly: r'$C000',
        effectiveAddress: null,
        value: null,
        A: 0,
        X: 0,
        Y: 0,
        SP: 0xFD,
        P: 0x24,
        scanline: 0,
        cycle: 0,
      ),
    );

    expect(line, startsWith(r'C000  JMP $C000'));

    executionLog.dispose();
  });

  test('dumpAsBytes encodes every printed line', () async {
    final executionLog = ExecutionLog(nes: remote, notifier: notifier)
      ..enable();

    handle.emit(ExecutionLogEvent(lines: [_line(0x8000)]));

    await pumpEventQueue();

    final bytes = executionLog.dumpAsBytes();

    expect(String.fromCharCodes(bytes), contains('8000'));

    executionLog.dispose();
  });

  test('a null nes does not throw on enable/disable', () {
    final executionLog = ExecutionLog(nes: null, notifier: notifier)
      ..enable()
      ..disable();

    expect(notifier.executionLogState.enabled, isFalse);

    executionLog.dispose();
  });
}
