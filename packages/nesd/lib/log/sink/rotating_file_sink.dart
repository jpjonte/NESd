import 'dart:convert';
import 'dart:io';

import 'package:nesd/log/log.dart';
import 'package:nesd/log/log_format.dart';
import 'package:nesd/log/log_sink.dart';
import 'package:path/path.dart' as p;

class RotatingFileSink extends LogSink {
  RotatingFileSink({required this.directory, this.maxBytes = 1024 * 1024});

  final String directory;
  final int maxBytes;

  RandomAccessFile? _file;
  int _bytes = 0;
  bool _disabled = false;

  bool get disabled => _disabled;

  String get path => p.join(directory, 'nesd.log');

  String get previousPath => p.join(directory, 'nesd.log.1');

  @override
  void add(LogRecord record) {
    if (_disabled || record.channel == LogChannel.telemetry) {
      return;
    }

    try {
      _file ??= _open();

      if (_bytes >= maxBytes) {
        _rotate();
        _file = _open();
      }

      final file = _file!;
      final bytes = utf8.encode('${formatRecordForFile(record)}\n');

      file.writeFromSync(bytes);

      _bytes += bytes.length;
    } on Object catch (e) {
      _disable(e);
    }
  }

  @override
  Future<void> close() async {
    _file?.closeSync();
    _file = null;
  }

  RandomAccessFile _open() {
    final dir = Directory(directory);

    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final file = File(path);

    _bytes = file.existsSync() ? file.lengthSync() : 0;

    return file.openSync(mode: FileMode.append);
  }

  void _rotate() {
    _file?.closeSync();
    _file = null;

    final previous = File(previousPath);

    if (previous.existsSync()) {
      previous.deleteSync();
    }

    File(path).renameSync(previousPath);

    _bytes = 0;
  }

  void _disable(Object error) {
    _disabled = true;

    try {
      _file?.closeSync();
    } on Object {
      // nothing else we can do
    }

    _file = null;

    log.app.error('Log file disabled after a write failure', error: error);
  }
}
