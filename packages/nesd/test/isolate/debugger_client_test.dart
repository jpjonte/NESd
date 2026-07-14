import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/debugger/breakpoint.dart';
import 'package:nesd/nes/debugger/debugger.dart';
import 'package:nesd/nes/debugger/debugger_state.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/isolate/nes_isolate.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/ui/emulator/cartridge_info.dart';
import 'package:nesd/ui/emulator/remote_nes.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal fake mirroring `_FakeNesIsolateHandle` in `remote_nes_test.dart`:
/// records sent commands and lets the test emit isolate events, so the real
/// `RemoteNes` (and, in turn, the real `Debugger` under test) run against a
/// controllable double instead of a spawned isolate.
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
  prgRamSize: 0,
  prgSaveRamSize: 0,
  tvSystem: TvSystem.ntsc,
);

DebuggerEvent _debuggerEvent({
  required DebuggerState state,
  Uint8List? cpuMemory,
}) => DebuggerEvent(
  state: state,
  cpuMemory: TransferableTypedData.fromList([cpuMemory ?? Uint8List(0x10000)]),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const fileHash = 'abc123';

  late _FakeNesIsolateHandle handle;
  late RemoteNes remote;
  late ProviderContainer container;
  late DebuggerStateNotifier notifier;
  late SettingsController settingsController;

  setUp(() async {
    handle = _FakeNesIsolateHandle();
    remote = RemoteNes(
      isolate: handle,
      romInfo: _testRomInfo(),
      fileHash: fileHash,
      hasZapper: false,
      cartridgeInfo: _testCartridgeInfo(),
    );

    SharedPreferences.setMockInitialValues({});

    final prefs = await SharedPreferences.getInstance();

    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );

    // `debuggerStateProvider`/`settingsControllerProvider` are autoDispose;
    // listening (rather than a one-off `read`) keeps the notifier instances
    // the test holds onto alive across this test's `pumpEventQueue` gaps.
    notifier = container
        .listen(debuggerStateProvider.notifier, (_, _) {})
        .read();
    settingsController = container
        .listen(settingsControllerProvider.notifier, (_, _) {})
        .read();
  });

  tearDown(() {
    remote.dispose();
    container.dispose();
  });

  Debugger build() => Debugger(
    nes: remote,
    notifier: notifier,
    settingsController: settingsController,
  );

  test('constructor activates the debugger and pushes stored breakpoints', () {
    settingsController.setBreakpoints(fileHash, [Breakpoint(0x8000)]);
    handle.commands.clear();

    build();

    expect(handle.commands, [
      isA<SetDebuggerActiveCommand>().having((c) => c.active, 'active', isTrue),
      isA<SetBreakpointsCommand>().having(
        (c) => c.breakpoints.map((b) => b.address),
        'breakpoint addresses',
        [0x8000],
      ),
    ]);
  });

  test(
    'DebuggerEvent merges backend state while preserving local UI fields',
    () async {
      final debugger = build();

      notifier.debuggerState = notifier.debuggerState.copyWith(
        showStack: true,
        executionLogOpen: true,
        selectedAddress: 0x4242,
      );

      handle.emit(
        _debuggerEvent(
          state: const DebuggerState(enabled: true, PC: 0x1234, A: 0x56),
        ),
      );

      await pumpEventQueue();

      expect(notifier.debuggerState.enabled, isTrue);
      expect(notifier.debuggerState.PC, 0x1234);
      expect(notifier.debuggerState.A, 0x56);
      expect(notifier.debuggerState.showStack, isTrue);
      expect(notifier.debuggerState.executionLogOpen, isTrue);
      expect(notifier.debuggerState.selectedAddress, 0x4242);

      debugger.dispose();
    },
  );

  test('read(address) answers from the transferred cpu memory dump', () async {
    final debugger = build();

    final memory = Uint8List(0x10000)..[0x1234] = 0x42;

    handle.emit(
      _debuggerEvent(state: const DebuggerState(), cpuMemory: memory),
    );

    await pumpEventQueue();

    expect(debugger.read(0x1234), 0x42);
    expect(debugger.read(0x0000), 0x00);

    debugger.dispose();
  });

  test('read(address) is 0 before any DebuggerEvent has arrived', () {
    final debugger = build();

    expect(debugger.read(0x1234), 0);

    debugger.dispose();
  });

  test(
    'read(address) is 0, not a RangeError, after a resume clears the dump',
    () async {
      final debugger = build();

      final memory = Uint8List(0x10000)..[0x1234] = 0x42;

      handle.emit(
        _debuggerEvent(state: const DebuggerState(), cpuMemory: memory),
      );

      await pumpEventQueue();

      expect(debugger.read(0x1234), 0x42);

      // Mirrors `DebuggerBackend`'s `ResumeNesEvent` handling, which sends
      // an empty dump alongside `enabled: false`.
      handle.emit(
        _debuggerEvent(state: const DebuggerState(), cpuMemory: Uint8List(0)),
      );

      await pumpEventQueue();

      expect(debugger.read(0x1234), 0);

      debugger.dispose();
    },
  );

  test('addBreakpoint sends AddBreakpointCommand', () {
    final debugger = build()..addBreakpoint(Breakpoint(0x9000));

    expect(
      handle.commands,
      contains(
        isA<AddBreakpointCommand>().having(
          (c) => c.breakpoint.address,
          'address',
          0x9000,
        ),
      ),
    );

    debugger.dispose();
  });

  test('removeBreakpoint sends RemoveBreakpointCommand', () {
    final debugger = build()..removeBreakpoint(Breakpoint(0x9000));

    expect(
      handle.commands,
      contains(
        isA<RemoveBreakpointCommand>().having(
          (c) => c.address,
          'address',
          0x9000,
        ),
      ),
    );

    debugger.dispose();
  });

  test(
    'BreakpointsEvent updates the notifier without persisting again',
    () async {
      final debugger = build();

      handle.emit(const BreakpointsEvent(fileHash: fileHash, breakpoints: []));

      await pumpEventQueue();

      final breakpoint = Breakpoint(0xA000);

      handle.emit(
        BreakpointsEvent(fileHash: fileHash, breakpoints: [breakpoint]),
      );

      await pumpEventQueue();

      expect(notifier.debuggerState.breakpoints.map((b) => b.address), [
        0xA000,
      ]);

      debugger.dispose();
    },
  );

  test(
    'hasBreakpoint/toggleBreakpointEnabled read from notifier state',
    () async {
      final debugger = build();
      final breakpoint = Breakpoint(0xB000);

      handle.emit(
        BreakpointsEvent(fileHash: fileHash, breakpoints: [breakpoint]),
      );

      await pumpEventQueue();

      expect(debugger.hasBreakpoint(0xB000), isTrue);
      expect(debugger.hasBreakpoint(0xC000), isFalse);

      debugger.toggleBreakpointEnabled(0xB000);

      expect(breakpoint.enabled, isFalse);
      expect(
        handle.commands,
        contains(
          isA<SetBreakpointsCommand>().having(
            (c) => c.breakpoints.single.enabled,
            'enabled',
            isFalse,
          ),
        ),
      );

      debugger.dispose();
    },
  );

  test(
    'toggleBreakpointExists adds when absent, removes when present',
    () async {
      final debugger = build()..toggleBreakpointExists(0xD000);

      expect(
        handle.commands,
        contains(
          isA<AddBreakpointCommand>().having(
            (c) => c.breakpoint.address,
            'address',
            0xD000,
          ),
        ),
      );

      handle.emit(
        BreakpointsEvent(fileHash: fileHash, breakpoints: [Breakpoint(0xD000)]),
      );

      await pumpEventQueue();

      debugger.toggleBreakpointExists(0xD000);

      expect(
        handle.commands,
        contains(
          isA<RemoveBreakpointCommand>().having(
            (c) => c.address,
            'address',
            0xD000,
          ),
        ),
      );

      debugger.dispose();
    },
  );

  test('showStack/hideStack/toggleExecutionLog/selectAddress stay local', () {
    final debugger = build();

    // The constructor's own initial-breakpoints push already sent one
    // `SetBreakpointsCommand`; only care about commands from here on.
    handle.commands.clear();

    debugger.showStack();
    expect(notifier.debuggerState.showStack, isTrue);

    debugger.hideStack();
    expect(notifier.debuggerState.showStack, isFalse);

    debugger.toggleExecutionLog();
    expect(notifier.debuggerState.executionLogOpen, isTrue);

    debugger.selectAddress(0x5000);
    expect(notifier.debuggerState.selectedAddress, 0x5000);

    debugger.selectAddress(0x5000);
    expect(notifier.debuggerState.selectedAddress, isNull);

    expect(handle.commands, isEmpty);

    debugger.dispose();
  });

  test('dispose deactivates the debugger and stops reacting to events', () {
    build().dispose();

    expect(
      handle.commands,
      contains(
        isA<SetDebuggerActiveCommand>().having(
          (c) => c.active,
          'active',
          isFalse,
        ),
      ),
    );
  });
}
