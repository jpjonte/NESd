import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/log/log_sink.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/isolate/nes_isolate.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/toast/toaster.dart';

import '../mocks.dart';

class _MockSettingsController extends Mock implements SettingsController {}

class _MockToaster extends Mock implements Toaster {}

class _MockRomManager extends Mock implements RomManager {}

class _MockFilesystem extends Mock implements Filesystem {}

class _SpySink extends LogSink {
  _SpySink({this.emitsAtOriginOnly = false});

  @override
  final bool emitsAtOriginOnly;

  final List<LogRecord> received = [];

  @override
  void add(LogRecord record) => received.add(record);
}

class _Harness {
  _Harness._({required this.handle});

  final FakeNesIsolateHandle handle;

  static Future<_Harness> load() async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.listen(nesStateProvider, (_, _) {});

    final settings = _MockSettingsController();

    when(() => settings.cheats).thenReturn(const {});
    when(() => settings.breakpoints).thenReturn(const {});
    when(() => settings.region).thenReturn(null);
    when(() => settings.rewind).thenReturn(false);
    when(() => settings.volume).thenReturn(1.0);
    when(() => settings.autoSave).thenReturn(false);
    when(() => settings.autoSaveInterval).thenReturn(5);
    when(() => settings.autoLoad).thenReturn(false);
    when(() => settings.logLevel).thenReturn(LogLevel.info);

    final romManager = _MockRomManager();

    when(() => romManager.load(any())).thenAnswer((_) async => null);

    final database = MockNesDatabase();
    final handle = FakeNesIsolateHandle();

    addTearDown(handle.dispose);

    Future<NesIsolateHandle> spawner() async => handle;

    final controller = NesController(
      nesState: container.read(nesStateProvider.notifier),
      spawner: spawner,
      router: Router(),
      settingsController: settings,
      toaster: _MockToaster(),
      romManager: romManager,
      filesystem: _MockFilesystem(),
      database: database,
      cartridgeFactory: CartridgeFactory(database: database),
      romImporter: FakeRomImporter(),
    );

    const file = FilesystemFile(
      path: '/test/log.nes',
      name: 'log.nes',
      type: FilesystemFileType.file,
    );

    await controller.loadRom(file, data: minimalValidRom());

    return _Harness._(handle: handle);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(
      const RomInfo(
        file: FilesystemFile(
          path: '/x',
          name: 'x',
          type: FilesystemFileType.file,
        ),
      ),
    );
  });

  tearDown(() async {
    await NesdLog.instance.close();

    NesdLog.install(NesdLog());
  });

  test(
    'a forwarded LogEvent is ingested, not re-emitted to origin-only sinks',
    () async {
      final harness = await _Harness.load();

      final originOnly = _SpySink(emitsAtOriginOnly: true);
      final ordinary = _SpySink();

      NesdLog.install(NesdLog(sinks: [originOnly, ordinary]));

      final record = LogRecord(
        time: DateTime.now(),
        level: LogLevel.error,
        channel: LogChannel.audio,
        message: 'PCM dump requires a loaded ROM',
        isolate: 'emulator',
      );

      harness.handle.emit(LogEvent(record: record));

      await pumpEventQueue();

      expect(
        originOnly.received.where((r) => identical(r, record)),
        isEmpty,
        reason:
            'ingest() must skip sinks flagged emitsAtOriginOnly, or '
            'telemetry lines would be double-emitted host-side',
      );
      expect(ordinary.received, contains(record));
    },
  );
}
