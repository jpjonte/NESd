#ifndef NESD_AUDIO_BACKEND_H_
#define NESD_AUDIO_BACKEND_H_

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Device-layer boundary. backend_miniaudio.cc is the only
// implementation today; a first-party platform backend replaces that
// one translation unit without touching the core or the public API.
typedef struct nesd_audio_backend nesd_audio_backend_t;

// Called on the OS audio thread to fill `out` with `samples` floats.
// Must always fill the whole buffer (the core pads silence on
// underrun).
typedef void (*nesd_audio_render_cb)(void *user, float *out,
                                     int32_t samples);

// Opens and starts a playback device. Returns NULL on failure.
// `null_device` selects a timer-driven fake device that consumes
// samples in real time.
nesd_audio_backend_t *nesd_audio_backend_open(
    int32_t sample_rate, int32_t channels, bool null_device,
    nesd_audio_render_cb render, void *user);

void nesd_audio_backend_close(nesd_audio_backend_t *backend);

// True when the opened device is the null backend — either requested
// or because no real device was available.
bool nesd_audio_backend_is_null_device(nesd_audio_backend_t *backend);

// Producer-thread hook, called on every push: restarts the device if
// the OS stopped it (device disconnect, backend error). Returns the
// lifetime count of successful restarts.
uint32_t nesd_audio_backend_ensure_running(
    nesd_audio_backend_t *backend);

#ifdef __cplusplus
}
#endif

#endif  // NESD_AUDIO_BACKEND_H_
