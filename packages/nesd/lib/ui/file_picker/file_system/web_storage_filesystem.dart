import 'dart:typed_data';

import 'package:idb_shim/idb.dart';
import 'package:nesd/exception/nesd_exception.dart';
import 'package:nesd/ui/file_picker/file_system/storage_filesystem.dart';

const _database = 'nesd';
const _store = 'files';

class _FileRecord {
  const _FileRecord({required this.bytes, required this.modified});

  factory _FileRecord.fromObject(Object record) {
    final map = record as Map;
    final bytes = map['bytes'];

    return _FileRecord(
      bytes: bytes is Uint8List
          ? bytes
          // IndexedDB may return a plain list, so cast it back to Uint8List
          : Uint8List.fromList((bytes as List).cast<int>()),
      modified: DateTime.fromMillisecondsSinceEpoch(map['modified'] as int),
    );
  }

  final Uint8List bytes;
  final DateTime modified;

  Map<String, Object> toMap() => {
    'bytes': bytes,
    'modified': modified.millisecondsSinceEpoch,
  };
}

class WebStorageFilesystem implements StorageFilesystem {
  WebStorageFilesystem._(this._db);

  static Future<WebStorageFilesystem> open(IdbFactory factory) async {
    try {
      final db = await factory.open(
        _database,
        version: 1,
        onUpgradeNeeded: (event) {
          event.database.createObjectStore(_store);
        },
      );

      return WebStorageFilesystem._(db);
    } on Object catch (e) {
      throw NesdException('Browser storage is unavailable: $e');
    }
  }

  final Database _db;

  @override
  Future<Uint8List?> read(String path) async {
    try {
      final record = await _files(idbModeReadOnly).getObject(path);

      if (record == null) {
        return null;
      }

      return _FileRecord.fromObject(record).bytes;
    } on Object catch (e) {
      throw NesdException('Failed to read $path from browser storage: $e');
    }
  }

  @override
  Future<void> write(String path, Uint8List data) async {
    try {
      await _files(
        idbModeReadWrite,
      ).put(_FileRecord(bytes: data, modified: DateTime.now()).toMap(), path);
    } on Object catch (e) {
      throw NesdException('Failed to write $path to browser storage: $e');
    }
  }

  @override
  Future<void> delete(String path) async {
    try {
      await _files(idbModeReadWrite).delete(path);
    } on Object catch (e) {
      throw NesdException('Failed to delete $path from browser storage: $e');
    }
  }

  @override
  Future<bool> exists(String path) async {
    try {
      return await _files(idbModeReadOnly).getObject(path) != null;
    } on Object catch (e) {
      throw NesdException(
        'Failed to check whether $path exists in browser storage: $e',
      );
    }
  }

  @override
  Future<List<String>> list(String directory) async {
    try {
      final prefix = directory.endsWith('/') ? directory : '$directory/';

      // Keys are strings ordered by UTF-16 code unit, so every key starting
      // with the prefix sorts below prefix + U+FFFF.
      final upperBound = '$prefix\uFFFF';

      final keys = await _files(
        idbModeReadOnly,
      ).getAllKeys(KeyRange.bound(prefix, upperBound));

      return keys
          .cast<String>()
          .where((key) => !key.substring(prefix.length).contains('/'))
          .toList();
    } on Object catch (e) {
      throw NesdException('Failed to list $directory in browser storage: $e');
    }
  }

  // Directories are implied by the file path, nothing to create.
  @override
  Future<void> createDirectory(String path) async {}

  @override
  Future<DateTime?> lastModified(String path) async {
    try {
      final record = await _files(idbModeReadOnly).getObject(path);

      if (record == null) {
        return null;
      }

      return _FileRecord.fromObject(record).modified;
    } on Object catch (e) {
      throw NesdException(
        'Failed to read metadata for $path from browser storage: $e',
      );
    }
  }

  ObjectStore _files(String mode) =>
      _db.transaction(_store, mode).objectStore(_store);
}
