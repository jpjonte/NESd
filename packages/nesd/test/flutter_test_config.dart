import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nesd/nes/rewind/rewind_codec.dart';
import 'package:nesd_audio/nesd_audio.dart';
import 'package:path/path.dart' as path;

import 'helpers/host_arch.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (kIsWeb) {
    return testMain();
  }

  if (Platform.isMacOS) {
    setRewindCodecLibraryPath('macos/eslz4-mac64.dylib');
  } else if (Platform.isLinux) {
    setRewindCodecLibraryPath('linux/eslz4-linux-${hostArch()}.so');
  } else if (Platform.isWindows) {
    setRewindCodecLibraryPath('windows/eslz4-win64.dll');
  } else {
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }

  NesdAudio.libraryPath = _hostAudioLibrary();

  final directory = Directory(path.join(Directory.systemTemp.path, 'nesd'));

  if (!directory.existsSync()) {
    await directory.create();
  }

  for (final file in directory.listSync()) {
    file.deleteSync(recursive: true);
  }

  await testMain();
}

/// Locates the host build of the nesd_audio library, building it via
/// CMake on first use. `flutter test` runs with CWD packages/nesd, so
/// paths are relative to that.
String _hostAudioLibrary() {
  const buildDir = '../nesd_audio/build/test';

  final library = Platform.isMacOS
      ? '$buildDir/libnesd_audio.dylib'
      : Platform.isLinux
      ? '$buildDir/libnesd_audio.so'
      : '$buildDir/Release/nesd_audio.dll';

  if (!File(library).existsSync()) {
    _buildHostAudioLibrary(buildDir, library);
  }

  return library;
}

/// Builds the host nesd_audio library via CMake.
///
/// `flutter test` runs suite processes concurrently, so several suites
/// can reach this on a fresh checkout at once; a cross-process exclusive
/// lock on `$buildDir.lock` serializes the build, and the library is
/// re-checked once the lock is held so only the first suite actually
/// builds it.
void _buildHostAudioLibrary(String buildDir, String library) {
  const sourceDir = '../nesd_audio/src';

  final lockFile = File('$buildDir.lock')..createSync(recursive: true);
  final lock = lockFile.openSync(mode: FileMode.write);

  try {
    lock.lockSync(FileLock.blockingExclusive);

    if (File(library).existsSync()) {
      return;
    }

    final ProcessResult configure;

    try {
      configure = Process.runSync('cmake', [
        '-S',
        sourceDir,
        '-B',
        buildDir,
        '-DCMAKE_BUILD_TYPE=Release',
      ]);
    } on ProcessException {
      throw StateError(
        'CMake not found; install it or run bin/build_test_libs.sh '
        'to build the host nesd_audio library.',
      );
    }

    if (configure.exitCode != 0) {
      throw StateError(
        'Failed to build the host nesd_audio library:\n'
        '${configure.stderr}',
      );
    }

    final build = Process.runSync('cmake', [
      '--build',
      buildDir,
      '--config',
      'Release',
    ]);

    if (build.exitCode != 0) {
      throw StateError(
        'Failed to build the host nesd_audio library:\n'
        '${build.stderr}',
      );
    }
  } finally {
    lock
      ..unlockSync()
      ..closeSync();
  }
}
