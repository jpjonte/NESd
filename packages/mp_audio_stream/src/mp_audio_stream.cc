#define MA_NO_DECODING
#define MA_NO_ENCODING
#define MINIAUDIO_IMPLEMENTATION
#include "./miniaudio/miniaudio.h"

#include "mp_audio_stream.h"
#include "spsc_ring.h"

#define DEVICE_FORMAT       ma_format_f32

typedef struct {
    ma_device device;

    spsc_ring_t ring;
    bool ring_initialized;

    ma_uint32 channels;

    bool is_exhaust;  // consumer-thread state only
    ma_uint32 exhaust_recover_size;

    std::atomic<ma_uint32> exhaust_count;
    std::atomic<ma_uint32> full_count;
} _ctx_t;

_ctx_t * _ctx = NULL;

void data_callback(ma_device* pDevice, void* pOutput, const void* pInput,
                   ma_uint32 frame_count)
{
    float* out = (float*)pOutput;
    ma_uint32 samples = frame_count * _ctx->channels;

    if (_ctx->is_exhaust &&
        _ctx->exhaust_recover_size > spsc_filled(&_ctx->ring)) {
        memset(out, 0, samples * sizeof(float));
        _ctx->exhaust_count.fetch_add(1, std::memory_order_relaxed);
        return;
    }
    _ctx->is_exhaust = false;

    ma_uint32 copied = spsc_pop(&_ctx->ring, out, samples);
    if (copied < samples) {
        memset(&out[copied], 0, (samples - copied) * sizeof(float));
        _ctx->is_exhaust = true;
        _ctx->exhaust_count.fetch_add(1, std::memory_order_relaxed);
    }
}

int ma_buffer_size() {
    return _ctx->ring.logical_size;
}

int ma_buffer_filled_size() {
    return spsc_filled(&_ctx->ring);
}

int ma_stream_push(float* buf, int length) {
    if (spsc_push(&_ctx->ring, buf, (uint32_t)length) != 0) {
        _ctx->full_count.fetch_add(1, std::memory_order_relaxed);
        return -1;
    }
    return 0;
}

ma_uint32 ma_stream_stat_exhaust_count() {
    return _ctx->exhaust_count.load(std::memory_order_relaxed);
}

ma_uint32 ma_stream_stat_full_count() {
    return _ctx->full_count.load(std::memory_order_relaxed);
}

void ma_stream_stat_reset() {
    _ctx->full_count.store(0, std::memory_order_relaxed);
    _ctx->exhaust_count.store(0, std::memory_order_relaxed);
}

void ma_stream_uninit() {
    ma_device_uninit(&_ctx->device);
}

int ma_stream_init(int max_buffer_size, int keep_buffer_size, int channels, int sample_rate)
{
    if (_ctx == NULL) {
        _ctx = (_ctx_t *)calloc(1,sizeof(_ctx_t));

        _ctx->ring_initialized = false;
        _ctx->is_exhaust = false;
        _ctx->exhaust_recover_size = 10 * 1024;
        _ctx->exhaust_count.store(0, std::memory_order_relaxed);
        _ctx->full_count.store(0, std::memory_order_relaxed);
    } else {
        ma_device_uninit(&_ctx->device);
    }

    ma_device_config deviceConfig;
 
    deviceConfig = ma_device_config_init(ma_device_type_playback);
    deviceConfig.playback.format   = DEVICE_FORMAT;
    deviceConfig.playback.channels = channels;
    deviceConfig.sampleRate        = sample_rate;
    deviceConfig.dataCallback      = data_callback;

    if (ma_device_init(NULL, &deviceConfig, &_ctx->device) != MA_SUCCESS) {
        printf("Failed to open playback device.\n");
        return -4;
    }

#ifdef MP_AUDIO_STREAM_DEBUG
    printf("Device Name: %s\n", _ctx->device.playback.name);
#endif

    if (_ctx->ring_initialized) {
        spsc_destroy(&_ctx->ring);
    }
    spsc_init(&_ctx->ring, (uint32_t)max_buffer_size);
    _ctx->ring_initialized = true;

    _ctx->exhaust_recover_size = keep_buffer_size;
    _ctx->is_exhaust = false;
    _ctx->exhaust_count.store(0, std::memory_order_relaxed);
    _ctx->full_count.store(0, std::memory_order_relaxed);

    _ctx->channels = channels;

    if (ma_device_start(&_ctx->device) != MA_SUCCESS) {
        printf("Failed to start playback device.\n");
        ma_device_uninit(&_ctx->device);
        return -5;
    }

    return 0;
}
