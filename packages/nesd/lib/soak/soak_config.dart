import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Configuration for one unattended audio soak run.
class SoakConfig {
  const SoakConfig({
    required this.romPath,
    required this.seconds,
    required this.pcm,
    required this.dirPath,
  });

  final String romPath;
  final int seconds;
  final bool pcm;

  /// Directory holding the pushed ROM and receiving stats.log/audio.pcm.
  final String dirPath;

  String get statsPath => p.join(dirPath, 'stats.log');

  String get pcmPath => p.join(dirPath, 'audio.pcm');
}

/// Marker file (JSON: `{"rom": "&lt;name in soak dir&gt;", "seconds": N,
/// "pcm": bool}`) pushed via adb into the app's external files dir under
/// soak/. Deleted before the run so a crash cannot loop the soak.
/// Mirrors `maybeRunBench` (bench_runner.dart); [baseDirectory] is a test
/// seam because path_provider channels are unavailable under flutter_test.
Future<SoakConfig?> maybeReadSoakConfig({Directory? baseDirectory}) async {
  final Directory base;

  if (baseDirectory case final directory?) {
    base = directory;
  } else {
    try {
      base = Platform.isAndroid
          ? (await getExternalStorageDirectory())!
          : await getApplicationSupportDirectory();
    } on Object {
      return null;
    }
  }

  final dir = Directory(p.join(base.path, 'soak'));
  final marker = File(p.join(dir.path, 'soak.json'));

  if (!marker.existsSync()) {
    return null;
  }

  final content = marker.readAsStringSync();

  marker.deleteSync();

  final Map<String, dynamic> config;

  try {
    config = jsonDecode(content) as Map<String, dynamic>;
  } on Object {
    return null;
  }

  final romName = config['rom'] as String?;

  if (romName == null) {
    return null;
  }

  return SoakConfig(
    romPath: p.join(dir.path, romName),
    seconds: (config['seconds'] as num?)?.toInt() ?? 600,
    pcm: config['pcm'] as bool? ?? true,
    dirPath: dir.path,
  );
}
