import 'dart:isolate';

class NesIsolateConfig {
  const NesIsolateConfig({
    required this.hostPort,
    this.lz4LibraryPath,
    this.audioLibraryPath,
    this.disableAudio = false,
  });

  final SendPort hostPort;

  final String? lz4LibraryPath;

  final String? audioLibraryPath;

  final bool disableAudio;
}
