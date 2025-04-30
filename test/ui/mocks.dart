import 'dart:typed_data';

import 'package:mocktail/mocktail.dart';
import 'package:mp_audio_stream/mp_audio_stream.dart';
import 'package:nesd/nes/database/database.dart';
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
