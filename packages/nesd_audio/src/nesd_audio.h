#ifndef NESD_AUDIO_H_
#define NESD_AUDIO_H_

#include <stdint.h>

#ifdef _WIN32
#define NESD_AUDIO_EXPORT __declspec(dllexport)
#else
#define NESD_AUDIO_EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

// Opaque stream handle. All API functions are called from the single
// thread that opened the stream (the emulator isolate); the OS audio
// callback runs on its own thread and communicates with it only
// through the internal SPSC ring.
typedef struct nesd_audio nesd_audio_t;

// nesd_audio_state() values.
enum {
    NESD_AUDIO_STATE_REAL_DEVICE = 0,    // playing on a real device
    NESD_AUDIO_STATE_NULL_DEVICE = 1,    // null device was requested
    NESD_AUDIO_STATE_NULL_FALLBACK = 2,  // real device unavailable
};

// Flag bits for nesd_audio_open().
enum {
    NESD_AUDIO_FLAG_NULL_DEVICE = 1 << 0,
};

// Opens a playback stream of f32 samples. `buffer_samples` is the ring
// capacity. After an underrun the callback emits silence until the
// ring refills to the largest device read seen plus `recover_samples`
// of margin (capped at capacity). Returns NULL only if everything including
// the null-device fallback failed.
NESD_AUDIO_EXPORT nesd_audio_t *nesd_audio_open(int32_t sample_rate,
                                                int32_t channels,
                                                int32_t buffer_samples,
                                                int32_t recover_samples,
                                                int32_t flags);

NESD_AUDIO_EXPORT void nesd_audio_close(nesd_audio_t *stream);

// Pushes up to `count` samples; returns the number actually written.
// A short write means the ring was near capacity and counts as one
// overrun.
NESD_AUDIO_EXPORT int32_t nesd_audio_push(nesd_audio_t *stream,
                                          const float *samples,
                                          int32_t count);

NESD_AUDIO_EXPORT int32_t nesd_audio_capacity(nesd_audio_t *stream);
NESD_AUDIO_EXPORT int32_t nesd_audio_filled(nesd_audio_t *stream);
NESD_AUDIO_EXPORT int32_t nesd_audio_state(nesd_audio_t *stream);

NESD_AUDIO_EXPORT uint32_t nesd_audio_underruns(nesd_audio_t *stream);
NESD_AUDIO_EXPORT uint32_t nesd_audio_overruns(nesd_audio_t *stream);

// Largest single device read since the last nesd_audio_reset_stats.
NESD_AUDIO_EXPORT uint32_t nesd_audio_pop_max(nesd_audio_t *stream);

// Lifetime count of device restarts after OS-initiated stops (device
// disconnect / route change). Not affected by nesd_audio_reset_stats.
NESD_AUDIO_EXPORT uint32_t nesd_audio_restarts(nesd_audio_t *stream);

NESD_AUDIO_EXPORT void nesd_audio_reset_stats(nesd_audio_t *stream);

#ifdef __cplusplus
}
#endif

#endif  // NESD_AUDIO_H_
