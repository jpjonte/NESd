import 'package:flutter/services.dart';
import 'package:nesd/exception/file_not_found.dart';
import 'package:nesd/exception/filesystem_exception.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

class AndroidFilesystem extends Filesystem {
  static const _channel = MethodChannel('nesd.jpj.dev/filesystem');

  @override
  Future<FilesystemFile?> chooseDirectory(String initialDirectory) async {
    try {
      final result = await _channel.invokeMethod<Map>('chooseDirectory', {
        'initialDirectory': initialDirectory,
      });

      if (result == null) {
        return null;
      }

      return FilesystemFile(
        path: result['path'] as String,
        name: result['name'] as String,
        type: FilesystemFileType.directory,
      );
    } on PlatformException catch (e, s) {
      Error.throwWithStackTrace(FilesystemException(previous: e), s);
    }
  }

  @override
  Future<bool> exists(String path) async {
    try {
      final result = await _channel.invokeMethod<bool>('exists', {
        'path': path,
      });

      return result ?? false;
    } on PlatformException catch (e, s) {
      Error.throwWithStackTrace(FilesystemException(previous: e), s);
    }
  }

  @override
  Future<bool> isDirectory(String path) async {
    try {
      final result = await _channel.invokeMethod<bool>('isDirectory', {
        'path': path,
      });

      return result ?? false;
    } on PlatformException catch (e, s) {
      Error.throwWithStackTrace(FilesystemException(previous: e), s);
    }
  }

  @override
  Future<bool> isFile(String path) async {
    try {
      final result = await _channel.invokeMethod<bool>('isFile', {
        'path': path,
      });

      return result ?? false;
    } on PlatformException catch (e, s) {
      Error.throwWithStackTrace(FilesystemException(previous: e), s);
    }
  }

  @override
  Future<List<FilesystemFile>> list(String path) async {
    try {
      final result = await _channel.invokeMethod<List>('list', {'path': path});

      if (result == null) {
        throw FileNotFound(path: path);
      }

      final files =
          (result as List<Object?>)
              .where((e) => e != null)
              .cast<Map>()
              .map((e) => FilesystemFile.fromJson(e as Map<String, dynamic>))
              .toList();

      return files;
    } on PlatformException catch (e, s) {
      Error.throwWithStackTrace(FilesystemException(previous: e), s);
    }
  }

  @override
  Future<Uint8List> read(String path) async {
    try {
      final result = await _channel.invokeMethod<Uint8List>('read', {
        'path': path,
      });

      if (result == null) {
        throw FileNotFound(path: path);
      }

      return result;
    } on PlatformException catch (e, s) {
      Error.throwWithStackTrace(FilesystemException(previous: e), s);
    }
  }

  @override
  Future<bool> hasPermission(String path) async {
    try {
      final result = await _channel.invokeMethod<bool>('hasPermission', {
        'path': path,
      });

      return result ?? false;
    } on PlatformException catch (e, s) {
      Error.throwWithStackTrace(FilesystemException(previous: e), s);
    }
  }

  @override
  Future<FilesystemFile?> parent(String path) async {
    try {
      final parent = await _channel.invokeMethod<Map>('parent', {'path': path});

      if (parent == null) {
        return null;
      }

      return FilesystemFile.fromJson(parent as Map<String, dynamic>);
    } on PlatformException catch (e, s) {
      Error.throwWithStackTrace(FilesystemException(previous: e), s);
    }
  }
}
