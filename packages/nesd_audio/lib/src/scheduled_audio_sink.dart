import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:nesd_audio/src/audio_context_resumer.dart';
import 'package:nesd_audio/src/audio_schedule.dart';
import 'package:nesd_audio/src/nesd_audio_backend.dart';
import 'package:nesd_audio/src/nesd_audio_state.dart';
import 'package:web/web.dart' as web;

class ScheduledAudioSink implements NesdAudioBackend {
  ScheduledAudioSink({
    required web.AudioContext context,
    required int capacity,
    required int recoverSamples,
  }) : _context = context,
       _resumer = AudioContextResumer(context),
       _schedule = AudioSchedule(
         capacity: capacity,
         sampleRate: context.sampleRate.toInt(),
         recoverSamples: recoverSamples,
         currentTime: () => context.currentTime,
       );

  final web.AudioContext _context;
  final AudioContextResumer _resumer;
  final AudioSchedule _schedule;

  final List<web.AudioBufferSourceNode> _live = [];

  bool _closed = false;

  @override
  int get capacity => _schedule.capacity;

  @override
  int get filled => _schedule.filled;

  @override
  int get underruns => _schedule.underruns;

  @override
  int get overruns => _schedule.overruns;

  @override
  int get popMax => 0;

  @override
  int get restarts => 0;

  @override
  NesdAudioState get state => _context.state == 'running'
      ? NesdAudioState.realDevice
      : NesdAudioState.nullFallback;

  @override
  int push(Float32List samples) {
    if (samples.isEmpty || _closed) {
      return 0;
    }

    _resumer.resumeIfSuspended();

    final slot = _schedule.push(samples.length);

    if (slot.samples == 0) {
      return 0;
    }

    final chunk = Float32List.sublistView(samples, 0, slot.samples);
    final buffer = _context.createBuffer(1, chunk.length, _context.sampleRate)
      ..copyToChannel(chunk.toJS, 0);

    final source = _context.createBufferSource()..buffer = buffer;

    source
      ..connect(_context.destination)
      ..onended = ((web.Event _) {
        _live.remove(source);
      }).toJS;

    source.start(slot.startTime);

    _live.add(source);

    return slot.samples;
  }

  @override
  void reset() {
    for (final source in _live) {
      source
        ..stop()
        ..disconnect();
    }

    _live.clear();
    _schedule.reset();
  }

  @override
  void resetStats() => _schedule.resetStats();

  @override
  void close() {
    _closed = true;

    reset();

    unawaited(_context.close().toDart.catchError((_) => null));
  }
}
