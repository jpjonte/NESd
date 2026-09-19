import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'screenshot_writer.g.dart';

const screenshotDirectoryName = 'NESd';

typedef ScreenshotWriter =
    Future<String> Function(String fileName, Uint8List png);

@riverpod
ScreenshotWriter screenshotWriter(Ref ref) {
  if (kIsWeb) {
    return const WebScreenshotWriter().write;
  }

  if (Platform.isAndroid) {
    return const AndroidScreenshotWriter().write;
  }

  return NativeScreenshotWriter(directory: defaultScreenshotDirectory).write;
}

class NativeScreenshotWriter {
  NativeScreenshotWriter({required this.directory});

  final Future<String> Function() directory;

  Future<String> write(String fileName, Uint8List png) async {
    final target = Directory(await directory());

    await target.create(recursive: true);

    final file = uniqueFile(target, fileName);

    await file.writeAsBytes(png, flush: true);

    return displayPath(file.path);
  }
}

class AndroidScreenshotWriter {
  const AndroidScreenshotWriter();

  static const _channel = MethodChannel('nesd.jpj.dev/filesystem');

  Future<String> write(String fileName, Uint8List png) async {
    try {
      final name = await _channel.invokeMethod<String>('savePicture', {
        'name': fileName,
        'directory': screenshotDirectoryName,
        'bytes': png,
      });

      return 'Pictures/$screenshotDirectoryName/${name ?? fileName}';
    } on PlatformException catch (e) {
      if (e.code != 'unsupported') {
        rethrow;
      }
    }

    return await NativeScreenshotWriter(
      directory: _appPicturesDirectory,
    ).write(fileName, png);
  }

  Future<String> _appPicturesDirectory() async {
    final directories = await getExternalStorageDirectories(
      type: StorageDirectory.pictures,
    );

    if (directories == null || directories.isEmpty) {
      throw const FileSystemException('No external storage available');
    }

    return p.join(directories.first.path, screenshotDirectoryName);
  }
}

class WebScreenshotWriter {
  const WebScreenshotWriter();

  Future<String> write(String fileName, Uint8List png) async {
    await FilePicker.saveFile(
      bytes: png,
      fileName: fileName,
      type: FileType.image,
    );

    return 'Downloads';
  }
}

File uniqueFile(Directory directory, String fileName) {
  final stem = p.basenameWithoutExtension(fileName);
  final extension = p.extension(fileName);

  var candidate = File(p.join(directory.path, fileName));

  for (var n = 2; candidate.existsSync(); n++) {
    candidate = File(p.join(directory.path, '$stem ($n)$extension'));
  }

  return candidate;
}

Future<String> defaultScreenshotDirectory() async =>
    p.join(await picturesDirectory(), screenshotDirectoryName);

Future<String> picturesDirectory() async {
  final environment = Platform.environment;

  if (Platform.isWindows) {
    final profile = environment['USERPROFILE'];

    if (profile == null) {
      throw const FileSystemException('USERPROFILE is not set');
    }

    return p.join(profile, 'Pictures');
  }

  final home = environment['HOME'];

  if (home == null) {
    throw const FileSystemException('HOME is not set');
  }

  if (Platform.isLinux) {
    return linuxPicturesDirectory(
      home: home,
      userDirs: await _readUserDirs(environment, home),
    );
  }

  return p.join(home, 'Pictures');
}

String linuxPicturesDirectory({required String home, String? userDirs}) {
  final match = RegExp(
    r'^\s*XDG_PICTURES_DIR\s*=\s*"?([^"\n]*)"?\s*$',
    multiLine: true,
  ).firstMatch(userDirs ?? '');

  final value = match?.group(1)?.trim();

  if (value == null || value.isEmpty) {
    return p.join(home, 'Pictures');
  }

  return p.normalize(value.replaceAll(r'$HOME', home));
}

Future<String?> _readUserDirs(
  Map<String, String> environment,
  String home,
) async {
  final configHome = environment['XDG_CONFIG_HOME'] ?? p.join(home, '.config');
  final file = File(p.join(configHome, 'user-dirs.dirs'));

  if (!file.existsSync()) {
    return null;
  }

  return await file.readAsString();
}

String displayPath(String path, {String? home}) {
  final root = home ?? Platform.environment['HOME'];

  if (root == null || root.isEmpty || !p.isWithin(root, path)) {
    return path;
  }

  return p.join('~', p.relative(path, from: root));
}
