import 'dart:async';
import 'dart:io';

import 'package:es_compression/lz4.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (Platform.isMacOS) {
    Lz4Codec.libraryPath = 'macos/eslz4-mac64.dylib';
  } else if (Platform.isLinux) {
    Lz4Codec.libraryPath = 'linux/eslz4-linux-x64.so';
  } else if (Platform.isWindows) {
    Lz4Codec.libraryPath = 'windows/eslz4-win64.dll';
  } else {
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }

  final directory = Directory('/tmp/nesd');

  await directory.create();

  for (final file in directory.listSync()) {
    file.deleteSync(recursive: true);
  }

  await testMain();
}
