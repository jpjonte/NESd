import 'dart:isolate';

import 'package:nesd/log/log_level.dart';

class NesIsolateConfig {
  const NesIsolateConfig({
    required this.hostPort,
    this.lz4LibraryPath,
    this.audioLibraryPath,
    this.disableAudio = false,
    this.logLevel = LogLevel.info,
  });

  final SendPort hostPort;

  final String? lz4LibraryPath;

  final String? audioLibraryPath;

  final bool disableAudio;

  final LogLevel logLevel;
}
