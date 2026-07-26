#define MA_NO_DECODING
#define MA_NO_ENCODING
#define MA_NO_RESOURCE_MANAGER
#define MA_NO_NODE_GRAPH
#define MA_NO_ENGINE
#define MA_NO_GENERATION
#define MINIAUDIO_IMPLEMENTATION
#include "./miniaudio/miniaudio.h"

#include <atomic>
#include <new>

#include "nesd_audio_backend.h"

struct nesd_audio_backend {
    ma_context context;
    ma_device device;
    int32_t sample_rate;
    ma_uint32 channels;
    nesd_audio_render_cb render;
    void *user;
    std::atomic<bool> needs_restart;
    uint32_t restarts;  // producer-thread state only
};

static void data_callback(ma_device *device, void *out, const void *in,
                          ma_uint32 frame_count) {
    auto *backend = (nesd_audio_backend_t *)device->pUserData;

    backend->render(backend->user, (float *)out,
                    (int32_t)(frame_count * backend->channels));
    (void)in;
}

// Runs on a miniaudio thread. A stop we did not request (AAudio device
// disconnect, backend error) schedules a restart; the producer thread
// performs it on its next push via nesd_audio_backend_ensure_running.
static void notification_callback(
    const ma_device_notification *event) {
    auto *backend = (nesd_audio_backend_t *)event->pDevice->pUserData;

    if (event->type == ma_device_notification_type_stopped) {
        backend->needs_restart.store(true, std::memory_order_release);
    }
}

static int device_init(nesd_audio_backend_t *backend) {
    ma_device_config config =
        ma_device_config_init(ma_device_type_playback);

    config.playback.format = ma_format_f32;
    config.playback.channels = backend->channels;
    config.sampleRate = (ma_uint32)backend->sample_rate;
    config.dataCallback = data_callback;
    config.notificationCallback = notification_callback;
    config.pUserData = backend;

    if (ma_device_init(&backend->context, &config,
                       &backend->device) != MA_SUCCESS) {
        return -1;
    }

    if (ma_device_start(&backend->device) != MA_SUCCESS) {
        ma_device_uninit(&backend->device);
        return -1;
    }

    return 0;
}

nesd_audio_backend_t *nesd_audio_backend_open(
    int32_t sample_rate, int32_t channels, bool null_device,
    nesd_audio_render_cb render, void *user) {
    auto *backend = new (std::nothrow) nesd_audio_backend_t();

    if (backend == NULL) {
        return NULL;
    }

    backend->sample_rate = sample_rate;
    backend->channels = (ma_uint32)channels;
    backend->render = render;
    backend->user = user;
    backend->needs_restart.store(false, std::memory_order_relaxed);
    backend->restarts = 0;

    ma_result context_result;

    if (null_device) {
        ma_backend null_backend = ma_backend_null;

        context_result =
            ma_context_init(&null_backend, 1, NULL, &backend->context);
    } else {
        context_result =
            ma_context_init(NULL, 0, NULL, &backend->context);
    }

    if (context_result != MA_SUCCESS) {
        delete backend;
        return NULL;
    }

    if (device_init(backend) != 0) {
        ma_context_uninit(&backend->context);
        delete backend;
        return NULL;
    }

    return backend;
}

void nesd_audio_backend_close(nesd_audio_backend_t *backend) {
    ma_device_uninit(&backend->device);
    ma_context_uninit(&backend->context);
    delete backend;
}

bool nesd_audio_backend_is_null_device(
    nesd_audio_backend_t *backend) {
    return backend->context.backend == ma_backend_null;
}

uint32_t nesd_audio_backend_ensure_running(
    nesd_audio_backend_t *backend) {
    if (!backend->needs_restart.exchange(
            false, std::memory_order_acq_rel)) {
        return backend->restarts;
    }

    // A device rebuild (below, possibly from an earlier push — see the
    // comment on the successful-rebuild branch) uninits the old device,
    // which fires the stopped notification and (re-)arms the flag;
    // ignore stops on a device that is in fact running.
    if (ma_device_get_state(&backend->device) ==
        ma_device_state_started) {
        return backend->restarts;
    }

    if (ma_device_start(&backend->device) == MA_SUCCESS) {
        backend->restarts++;
        return backend->restarts;
    }

    // Some disconnects need a full device rebuild (AAudio).
    ma_device_uninit(&backend->device);

    if (device_init(backend) == 0) {
        backend->restarts++;

        // Leave needs_restart armed: ma_device_uninit above already
        // re-arms it via the stopped notification, and clearing it here
        // could also erase a genuine stop that fires in the window
        // after the new device starts. Leaving it armed just costs one
        // no-op pass through the state-started guard above on the next
        // push; a real stop is never lost.
    } else {
        // The route change may still be settling; retry on a later
        // push.
        backend->needs_restart.store(true, std::memory_order_release);
    }

    return backend->restarts;
}
