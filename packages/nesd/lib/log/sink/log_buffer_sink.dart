import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nesd/log/log_channel.dart';
import 'package:nesd/log/log_record.dart';
import 'package:nesd/log/log_sink.dart';

class LogBufferSink extends LogSink with ChangeNotifier {
  LogBufferSink({this.capacity = 2000, this.telemetryCapacity = 200});

  final int capacity;

  final int telemetryCapacity;

  final List<LogRecord> _records = [];

  bool _notificationScheduled = false;

  bool _disposed = false;

  List<LogRecord> get records => List.unmodifiable(_records);

  @override
  void add(LogRecord record) {
    _records.add(record);

    final telemetryCount = _records
        .where((r) => r.channel == LogChannel.telemetry)
        .length;

    if (telemetryCount > telemetryCapacity) {
      _removeOldestTelemetry();
    }

    if (_records.length > capacity) {
      _records.removeRange(0, _records.length - capacity);
    }

    _scheduleNotification();
  }

  void _scheduleNotification() {
    if (_notificationScheduled) {
      return;
    }

    _notificationScheduled = true;

    scheduleMicrotask(() {
      _notificationScheduled = false;

      if (_disposed) {
        return;
      }

      notifyListeners();
    });
  }

  void _removeOldestTelemetry() {
    final index = _records.indexWhere((r) => r.channel == LogChannel.telemetry);

    if (index != -1) {
      _records.removeAt(index);
    }
  }

  void clear() {
    _records.clear();

    _scheduleNotification();
  }

  @override
  void dispose() {
    _disposed = true;

    super.dispose();
  }

  @override
  Future<void> close() async => dispose();
}
