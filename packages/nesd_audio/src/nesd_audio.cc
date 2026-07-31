#include "nesd_audio.h"

#include <atomic>
#include <cstring>
#include <new>

#include "nesd_audio_backend.h"
#include "spsc_ring.h"

struct nesd_audio {
    spsc_ring_t ring;
    int32_t recover_samples;
    int32_t state;

    bool is_exhaust;  // consumer-thread state only

    std::atomic<uint32_t> underruns;
    std::atomic<uint32_t> overruns;

    uint32_t restarts;  // producer-thread mirror of the backend count

    nesd_audio_backend_t *backend;
};

// Runs on the OS audio thread. After an underrun, keeps emitting
// silence until the ring refills to recover_samples so playback
// resumes with runway instead of immediately starving again.
static void render(void *user, float *out, int32_t samples) {
    auto *stream = (nesd_audio_t *)user;

    if (stream->is_exhaust &&
        (int32_t)spsc_filled(&stream->ring) <
            stream->recover_samples) {
        memset(out, 0, (size_t)samples * sizeof(float));
        stream->underruns.fetch_add(1, std::memory_order_relaxed);
        return;
    }

    stream->is_exhaust = false;

    uint32_t copied = spsc_pop(&stream->ring, out, (uint32_t)samples);

    if ((int32_t)copied < samples) {
        memset(out + copied, 0,
               ((size_t)samples - copied) * sizeof(float));
        stream->is_exhaust = true;
        stream->underruns.fetch_add(1, std::memory_order_relaxed);
    }
}

nesd_audio_t *nesd_audio_open(int32_t sample_rate, int32_t channels,
                              int32_t buffer_samples,
                              int32_t recover_samples,
                              int32_t flags) {
    auto *stream = new (std::nothrow) nesd_audio_t();

    if (stream == NULL) {
        return NULL;
    }

    spsc_init(&stream->ring, (uint32_t)buffer_samples);
    stream->recover_samples = recover_samples;
    stream->is_exhaust = false;
    stream->underruns.store(0, std::memory_order_relaxed);
    stream->overruns.store(0, std::memory_order_relaxed);
    stream->restarts = 0;

    const bool want_null =
        (flags & NESD_AUDIO_FLAG_NULL_DEVICE) != 0;

    stream->backend = nesd_audio_backend_open(
        sample_rate, channels, want_null, render, stream);

    if (stream->backend == NULL && !want_null) {
        stream->backend = nesd_audio_backend_open(
            sample_rate, channels, true, render, stream);
    }

    if (stream->backend == NULL) {
        spsc_destroy(&stream->ring);
        delete stream;
        return NULL;
    }

    if (want_null) {
        stream->state = NESD_AUDIO_STATE_NULL_DEVICE;
    } else if (nesd_audio_backend_is_null_device(stream->backend)) {
        stream->state = NESD_AUDIO_STATE_NULL_FALLBACK;
    } else {
        stream->state = NESD_AUDIO_STATE_REAL_DEVICE;
    }

    return stream;
}

void nesd_audio_close(nesd_audio_t *stream) {
    nesd_audio_backend_close(stream->backend);
    spsc_destroy(&stream->ring);
    delete stream;
}

int32_t nesd_audio_push(nesd_audio_t *stream, const float *samples,
                        int32_t count) {
    stream->restarts =
        nesd_audio_backend_ensure_running(stream->backend);

    int32_t free_samples = (int32_t)stream->ring.logical_size -
                           (int32_t)spsc_filled(&stream->ring);
    int32_t writable = count < free_samples ? count : free_samples;

    if (writable < count) {
        stream->overruns.fetch_add(1, std::memory_order_relaxed);
    }

    if (writable <= 0) {
        return 0;
    }

    spsc_push(&stream->ring, samples, (uint32_t)writable);

    return writable;
}

int32_t nesd_audio_capacity(nesd_audio_t *stream) {
    return (int32_t)stream->ring.logical_size;
}

int32_t nesd_audio_filled(nesd_audio_t *stream) {
    return (int32_t)spsc_filled(&stream->ring);
}

int32_t nesd_audio_state(nesd_audio_t *stream) {
    return stream->state;
}

uint32_t nesd_audio_underruns(nesd_audio_t *stream) {
    return stream->underruns.load(std::memory_order_relaxed);
}

uint32_t nesd_audio_overruns(nesd_audio_t *stream) {
    return stream->overruns.load(std::memory_order_relaxed);
}

uint32_t nesd_audio_restarts(nesd_audio_t *stream) {
    return stream->restarts;
}

void nesd_audio_reset_stats(nesd_audio_t *stream) {
    stream->underruns.store(0, std::memory_order_relaxed);
    stream->overruns.store(0, std::memory_order_relaxed);
}
