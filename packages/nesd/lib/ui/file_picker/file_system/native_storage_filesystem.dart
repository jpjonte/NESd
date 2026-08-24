import 'dart:io';
import 'dart:typed_data';

import 'package:nesd/exception/nesd_exception.dart';
import 'package:nesd/ui/file_picker/file_system/storage_filesystem.dart';
import 'package:path/path.dart' as p;

class NativeStorageFilesystem implements StorageFilesystem {
  @override
  Future<Uint8List?> read(String path) async {
    try {
      return File(path).readAsBytesSync();
    } on PathNotFoundException {
      return null;
    } on Object catch (e) {
      throw NesdException('Failed to read $path: $e');
    }
  }

  @override
  Future<void> write(String path, Uint8List data) async {
    try {
      Directory(p.dirname(path)).createSync(recursive: true);

      // write, then rename so concurrent readers never see a partial file.
      File('$path.tmp')
        ..writeAsBytesSync(data)
        ..renameSync(path);
    } on Object catch (e) {
      throw NesdException('Failed to write $path: $e');
    }
  }

  @override
  Future<void> delete(String path) async {
    try {
      File(path).deleteSync();
    } on PathNotFoundException {
      // already gone
    } on Object catch (e) {
      throw NesdException('Failed to delete $path: $e');
    }
  }

  @override
  Future<bool> exists(String path) async {
    try {
      return File(path).existsSync();
    } on Object catch (e) {
      throw NesdException('Failed to check whether $path exists: $e');
    }
  }

  @override
  Future<List<String>> list(String directory) async {
    try {
      return Directory(
        directory,
      ).listSync().whereType<File>().map((f) => f.path).toList();
    } on PathNotFoundException {
      return [];
    } on Object catch (e) {
      throw NesdException('Failed to list $directory: $e');
    }
  }

  @override
  Future<void> createDirectory(String path) async {
    try {
      Directory(path).createSync(recursive: true);
    } on Object catch (e) {
      throw NesdException('Failed to create directory $path: $e');
    }
  }

  @override
  Future<DateTime?> lastModified(String path) async {
    try {
      return File(path).lastModifiedSync();
    } on PathNotFoundException {
      return null;
    } on Object catch (e) {
      throw NesdException('Failed to read metadata for $path: $e');
    }
  }
}
