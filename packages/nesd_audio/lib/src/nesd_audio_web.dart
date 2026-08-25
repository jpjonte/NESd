library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:nesd_audio/src/nesd_audio_backend.dart';
import 'package:nesd_audio/src/nesd_audio_state.dart';
import 'package:nesd_audio/src/silent_audio_sink.dart';
import 'package:nesd_audio/src/web_audio_queue.dart';
import 'package:web/web.dart' as web;

const _workletSource = '''
class NesdAudioProcessor extends AudioWorkletProcessor {
  constructor(options) {
    super();

    this.recover = options.processorOptions.recoverSamples;

    this.chunks = [];

    this.offset = 0;
    this.fill = 0;
    this.received = 0;
    this.underruns = 0;
    this.quanta = 0;

    // Mirrors the native ring's recovery hysteresis: silence until the
    // ring holds `recover` samples, both at start and after every
    // underrun, so playback never thrashes on a sliver of buffer.
    this.starved = true;

    this.port.onmessage = (event) => {
      if (event.data === 'reset') {
        this.chunks = [];

        this.offset = 0;
        this.fill = 0;
        this.received = 0;

        // Re-arm the recovery hysteresis so the empty ring doesn't
        // count as one spurious underrun.
        this.starved = true;

        return;
      }

      this.chunks.push(event.data);

      this.fill += event.data.length;
      this.received += event.data.length;
    };
  }

  process(inputs, outputs) {
    const out = outputs[0][0];

    if (this.starved) {
      if (this.fill >= this.recover) {
        this.starved = false;
      }
    }

    if (!this.starved) {
      let written = 0;

      while (written < out.length && this.chunks.length > 0) {
        const chunk = this.chunks[0];

        const n = Math.min(out.length - written, chunk.length - this.offset);

        out.set(chunk.subarray(this.offset, this.offset + n), written);

        written += n;

        this.offset += n;
        this.fill -= n;

        if (this.offset >= chunk.length) {
          this.chunks.shift();
          this.offset = 0;
        }
      }

      // One underrun per starvation event, like the native backend
      if (written < out.length) {
        this.underruns++;
        this.starved = true;
      }
    }

    if (++this.quanta >= 8) {
      this.quanta = 0;
      this.port.postMessage({
        fill: this.fill,
        underruns: this.underruns,
        received: this.received,
      });
      this.underruns = 0;
    }

    return true;
  }
}

registerProcessor('nesd-audio', NesdAudioProcessor);
''';

class NesdAudio implements NesdAudioBackend {
  NesdAudio._({required int capacity, required this._nullDevice})
    : _queue = WebAudioQueue(capacity: capacity);

  /// Opens an AudioWorklet-backed playback stream of f32 samples.
  ///
  /// [channels] is ignored, the worklet renders mono.
  factory NesdAudio.open({
    required int sampleRate,
    required int channels,
    required int bufferSamples,
    required int recoverSamples,
    bool nullDevice = false,
  }) {
    final audio = NesdAudio._(capacity: bufferSamples, nullDevice: nullDevice);

    if (!nullDevice) {
      audio._initialize(sampleRate, recoverSamples);
    }

    return audio;
  }

  /// Ignored on web.
  static String? libraryPath;

  final WebAudioQueue _queue;
  final bool _nullDevice;
  final List<Float32List> _preInit = [];

  SilentAudioSink? _silentSink;

  web.AudioContext? _context;
  web.AudioWorkletNode? _node;
  bool _ready = false;
  bool _closed = false;
  bool _resumeFailureLogged = false;

  @override
  int get capacity => _queue.capacity;

  @override
  int get filled => _silentSink?.filled ?? _queue.estimatedFill;

  @override
  int get underruns => _queue.underruns;

  @override
  int get overruns => _queue.overruns;

  @override
  int get restarts => 0;

  @override
  NesdAudioState get state {
    if (_nullDevice) {
      return NesdAudioState.nullDevice;
    }

    return _context?.state == 'running'
        ? NesdAudioState.realDevice
        : NesdAudioState.nullFallback;
  }

  @override
  int push(Float32List samples) {
    if (samples.isEmpty || _closed) {
      return 0;
    }

    if (_nullDevice) {
      return samples.length;
    }

    if (_silentSink case final sink?) {
      return sink.push(samples.length);
    }

    // A suspended context (autoplay policy) consumes nothing, so the
    // queue saturates. Keep retrying the resume even when nothing fits.
    _resumeIfSuspended();

    final written = _queue.push(samples.length);

    if (written == 0) {
      return 0;
    }

    final chunk = written == samples.length
        ? Float32List.fromList(samples)
        : Float32List.fromList(Float32List.sublistView(samples, 0, written));

    if (_ready) {
      _post(chunk);
    } else {
      _preInit.add(chunk);
    }

    return written;
  }

  @override
  void reset() {
    _preInit.clear();
    _node?.port.postMessage('reset'.toJS);
    _queue.reset();
  }

  @override
  void resetStats() => _queue.resetStats();

  @override
  void close() {
    _closed = true;

    reset();

    _node?.disconnect();
    _node = null;

    final context = _context;
    _context = null;

    if (context != null) {
      unawaited(context.close().toDart.catchError((_) => null));
    }
  }

  void _initialize(int sampleRate, int recoverSamples) {
    final context = web.AudioContext(
      web.AudioContextOptions(sampleRate: sampleRate),
    );

    _context = context;

    // AudioWorklet only exists in secure contexts (https or localhost).
    // On plain HTTP the non-nullable `audioWorklet` getter would throw a
    // null check under wasm.
    if (context.getProperty('audioWorklet'.toJS).isUndefinedOrNull) {
      _fallBackToSilentSink(
        context,
        sampleRate,
        'AudioWorklet is unavailable (insecure context?)',
      );

      return;
    }

    final blob = web.Blob(
      [_workletSource.toJS].toJS,
      web.BlobPropertyBag(type: 'application/javascript'),
    );
    final url = web.URL.createObjectURL(blob);

    unawaited(
      context.audioWorklet
          .addModule(url)
          .toDart
          .then((_) {
            web.URL.revokeObjectURL(url);

            if (_closed) {
              return;
            }

            // assume mono output for now
            final node = web.AudioWorkletNode(
              context,
              'nesd-audio',
              web.AudioWorkletNodeOptions(
                outputChannelCount: [1.toJS].toJS,
                processorOptions:
                    {'recoverSamples': recoverSamples}.jsify()! as JSObject,
              ),
            );

            node.connect(context.destination);
            node.port.onmessage = _handleWorkletMessage.toJS;

            _node = node;
            _ready = true;

            for (final chunk in _preInit) {
              _post(chunk);
            }

            _preInit.clear();

            _resumeIfSuspended();
          })
          .catchError((Object error) {
            web.URL.revokeObjectURL(url);

            if (_closed) {
              return;
            }

            // Without the fallback the queue would sit at capacity
            // forever and stall the pacing governor.
            _fallBackToSilentSink(
              context,
              sampleRate,
              'AudioWorklet module load failed: $error',
            );
          }),
    );
  }

  /// Keeps the emulator running at full speed, just without sound.
  void _fallBackToSilentSink(
    web.AudioContext context,
    int sampleRate,
    String reason,
  ) {
    web.console.warn('nesd_audio: $reason; continuing without sound'.toJS);

    _silentSink = SilentAudioSink(
      capacity: _queue.capacity,
      sampleRate: sampleRate,
    );

    _context = null;
    _node = null;
    _ready = false;

    _preInit.clear();

    unawaited(context.close().toDart.catchError((_) => null));
  }

  void _handleWorkletMessage(web.MessageEvent event) {
    final data = event.data;

    if (data == null || !data.isA<JSObject>()) {
      return;
    }

    final object = data as JSObject;
    final fill = (object.getProperty('fill'.toJS)! as JSNumber).toDartInt;
    final underruns =
        (object.getProperty('underruns'.toJS)! as JSNumber).toDartInt;
    final received =
        (object.getProperty('received'.toJS)! as JSNumber).toDartInt;

    _queue.report(fill: fill, underruns: underruns, received: received);
  }

  void _post(Float32List chunk) {
    _node?.port.postMessage(chunk.toJS);
  }

  void _resumeIfSuspended() {
    final context = _context;

    if (context != null && context.state == 'suspended') {
      unawaited(
        context.resume().toDart.catchError((Object error) {
          if (!_resumeFailureLogged) {
            _resumeFailureLogged = true;

            web.console.warn(
              'nesd_audio: AudioContext.resume() failed: $error'.toJS,
            );
          }

          return null;
        }),
      );
    }
  }
}
