import 'dart:async';
import 'dart:typed_data';

import 'package:mocktail/mocktail.dart';
import 'package:mp_audio_stream/mp_audio_stream.dart';
import 'package:nesd/audio/null_audio_stream.dart';
import 'package:nesd/nes/database/database.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/isolate/nes_isolate.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/nes/isolate/nes_worker.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class MockAudioStream extends Mock implements AudioStream {
  @override
  int getBufferFilledSize() => 0;

  @override
  int getBufferSize() => 192000; // 48 kHz * 4 bytes * 1 second

  @override
  int push(Float32List buf) => 0;

  @override
  int init({
    int bufferMilliSec = 3000,
    int waitingBufferMilliSec = 100,
    int channels = 1,
    int sampleRate = 44100,
  }) {
    return 0;
  }

  AudioStreamStat nextStat = AudioStreamStat.empty();

  @override
  AudioStreamStat stat() => nextStat;

  @override
  void resetStat() {
    nextStat = AudioStreamStat.empty();
  }
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

  @override
  Future<List<FilesystemFile>> list(String path) async {
    return [
      for (final entry in _files.entries)
        FilesystemFile(
          path: p.basename(entry.key),
          name: p.basename(entry.key),
          type: FilesystemFileType.file,
        ),
    ];
  }

  @override
  Future<bool> exists(String path) async {
    return _files.entries.any((entry) => entry.key.startsWith(path));
  }

  @override
  Future<bool> isDirectory(String path) async {
    return _files.entries.any((entry) => entry.key.startsWith(path));
  }
}

class MockNesDatabase extends Mock implements NesDatabase {
  @override
  NesDatabaseEntry? find(RomInfo info) => null;
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
/// Instead of spawning a real isolate (no miniaudio symbols under
/// `flutter_tester`, and isolate messages invisible to `FakeAsync`), it runs
/// a real [NesWorker] on the test isolate with [NullAudioStream]. Commands
/// are forwarded to the worker and its events are re-published, so the full
/// emulator protocol (ROM loading, save states, SRAM, thumbnails) behaves
/// exactly as in production, deterministically driven by the test's own
/// pumping. Override `nesIsolateSpawnerProvider` with `() async =>
/// FakeNesIsolateHandle()` to install it.
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
      audioStreamFactory: NullAudioStream.new,
    );
  }

  final StreamController<NesIsolateEvent> _events =
      StreamController<NesIsolateEvent>.broadcast();

  late final NesWorker _worker;

  @override
  Stream<NesIsolateEvent> get events => _events.stream;

  @override
  void send(NesCommand command) {
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
    // are listening before this arrives. Mirrors the real worker's async
    // dispatch, without relying on a real `Timer` (which the widget test
    // clock won't advance without an explicit pump).
    scheduleMicrotask(() {
      if (!_events.isClosed) {
        _events.add(const RomLoadFailedEvent(message: 'forced test failure'));
      }
    });
  }

  @override
  Future<void> dispose() async {
    await _worker.shutdown();

    await _events.close();
  }
}
