import 'dart:async';
import 'dart:typed_data';

import 'package:mocktail/mocktail.dart';
import 'package:nesd/nes/database/database.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/isolate/nes_isolate.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/nes/isolate/nes_worker.dart';
import 'package:nesd/ui/emulator/rom_importer.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/file_picker/file_system/storage_filesystem.dart';
import 'package:nesd_audio/nesd_audio.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class FakeNesdAudio implements NesdAudio {
  int underrunsValue = 0;

  // Half full for proper emulation pacing
  int filledValue = 96000;

  @override
  int get capacity => 192000; // 48 kHz * 4 bytes * 1 second

  @override
  int get filled => filledValue;

  @override
  int get underruns => underrunsValue;

  @override
  int get overruns => 0;

  @override
  int get popMax => 0;

  @override
  int get restarts => 0;

  @override
  NesdAudioState get state => NesdAudioState.nullDevice;

  @override
  int push(Float32List samples) => samples.length;

  @override
  void reset() {}

  @override
  void resetStats() {
    underrunsValue = 0;
  }

  @override
  void close() {}
}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockFileSystem extends Mock implements Filesystem {
  final Map<String, Uint8List> _files = {};

  @override
  Future<Uint8List> read(String path) async {
    if (!_files.containsKey(path)) {
      throw Exception('File not found: $path');
    }

    return _files[path]!;
  }

  void addFile(String path, Uint8List data) {
    _files[path] = data;
  }

  String _prefix(String path) => path.endsWith('/') ? path : '$path/';

  @override
  Future<List<FilesystemFile>> list(String path) async {
    final prefix = _prefix(path);
    final children = <String, FilesystemFileType>{};

    for (final key in _files.keys) {
      if (!key.startsWith(prefix)) {
        continue;
      }

      final rest = key.substring(prefix.length);
      final slash = rest.indexOf('/');

      if (slash == -1) {
        children[rest] = FilesystemFileType.file;
      } else {
        children[rest.substring(0, slash)] = FilesystemFileType.directory;
      }
    }

    return [
      for (final MapEntry(key: name, value: type) in children.entries)
        FilesystemFile(path: '$prefix$name', name: name, type: type),
    ];
  }

  // Mirrors NativeFilesystem: the root is its own parent, never null.
  @override
  Future<FilesystemFile?> parent(String path) async {
    final parentPath = p.dirname(path);

    return FilesystemFile(
      path: parentPath,
      name: parentPath,
      type: FilesystemFileType.directory,
    );
  }

  @override
  Future<bool> exists(String path) async {
    return _files.containsKey(path) || await isDirectory(path);
  }

  @override
  Future<bool> isDirectory(String path) async {
    return _files.keys.any((key) => key.startsWith(_prefix(path)));
  }
}

class MockNesDatabase extends Mock implements NesDatabase {
  @override
  NesDatabaseEntry? find(RomInfo info) => null;
}

class MockStorageFilesystem extends Mock implements StorageFilesystem {}

class FakeRomImporter implements RomImporter {
  @override
  Future<FilesystemFile?> pickRom() async => null;
}

/// A [FilesystemFile.path] that, when passed to [FakeNesIsolateHandle.send]
/// in a [LoadRomCommand], synthesizes a [RomLoadFailedEvent] instead of
/// forwarding the command to the real worker.
///
/// Real cartridge/NES parsing is deterministic and shared verbatim between
/// `NesController.loadRom`'s client-side pre-parse and the worker's own
/// parse, so a ROM payload that passes the client-side parse (needed to
/// exercise `loadRom`'s post-parse failure-handling, e.g. the orphaned
/// `RemoteNes` bug) will also succeed on the worker side. There is no
/// naturally-occurring byte sequence that diverges between the two. This
/// path-based hook lets tests force a worker-reported failure regardless of
/// ROM content, so `loadRom`'s `RomLoadFailedEvent` branch can be exercised
/// deterministically. Register the accompanying ROM bytes (any bytes that
/// parse as a valid cartridge, content is otherwise irrelevant) under this
/// path in the test's [Filesystem] fake.
///
/// Deliberately outside `/test/roms` so it doesn't show up in
/// `MockFileSystem.list('/test/roms')`-driven file-picker assertions.
const forcedRomLoadFailurePath = '/test/fixtures/force_load_failure.nes';

/// A minimal but structurally-valid iNES ROM (mapper 0, 1x16KB PRG bank,
/// CHR RAM): a real header plus zeroed PRG data, just enough to pass
/// `CartridgeFactory.fromFile` so `NesController.loadRom` reaches
/// [forcedRomLoadFailurePath]'s worker-failure hook.
Uint8List minimalValidRom() {
  final rom = Uint8List(16 + 0x4000);

  rom[0] = 0x4E; // 'N'
  rom[1] = 0x45; // 'E'
  rom[2] = 0x53; // 'S'
  rom[3] = 0x1A;
  rom[4] = 1; // 1x 16KB PRG bank

  return rom;
}

/// In-process [NesIsolateHandle] for widget tests.
///
/// Runs a real [NesWorker] on the test isolate with [FakeNesdAudio] instead of
/// a separate isolate.
///
/// See [forcedRomLoadFailurePath] for forcing a `RomLoadFailedEvent` without
/// a real worker-side parse failure.
class FakeNesIsolateHandle implements NesIsolateHandle {
  FakeNesIsolateHandle() {
    _worker = NesWorker(
      send: (event) {
        if (!_events.isClosed) {
          _events.add(event);
        }
      },
      audioFactory: FakeNesdAudio.new,
    );
  }

  final StreamController<NesIsolateEvent> _events =
      StreamController<NesIsolateEvent>.broadcast();

  final List<NesCommand> sentCommands = [];

  late final NesWorker _worker;

  @override
  Stream<NesIsolateEvent> get events => _events.stream;

  @override
  void send(NesCommand command) {
    sentCommands.add(command);

    if (command case LoadRomCommand(
      file: final file,
    ) when file.path == forcedRomLoadFailurePath) {
      _forceLoadFailure();

      return;
    }

    unawaited(_worker.handleCommand(command));
  }

  void _forceLoadFailure() {
    // Defer by a microtask so callers that subscribe to `events` right
    // after calling `send` (e.g. `NesController.loadRom`'s `firstWhere`)
    // are listening before this arrives.
    scheduleMicrotask(() {
      if (!_events.isClosed) {
        _events.add(const RomLoadFailedEvent(message: 'forced test failure'));
      }
    });
  }

  /// Injects [event] into [events] as if the worker had sent it.
  void emit(NesIsolateEvent event) {
    if (!_events.isClosed) {
      _events.add(event);
    }
  }

  @override
  Future<void> dispose() async {
    await _worker.shutdown();

    await _events.close();
  }
}
