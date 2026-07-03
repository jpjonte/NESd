#define MA_NO_DECODING
#define MA_NO_ENCODING
#define MINIAUDIO_IMPLEMENTATION
#include "./miniaudio/miniaudio.h"

#include "mp_audio_stream.h"

#define DEVICE_FORMAT       ma_format_f32

typedef struct {
    ma_device device;

    ma_uint32 buf_size;

    float *buf;
    ma_uint32 buf_end;
    ma_uint32 buf_start;

    ma_uint32 channels;

    bool is_exhaust;
    ma_uint32 exhaust_recover_size;

    ma_uint32 exhaust_count;
    ma_uint32 full_count;

} _ctx_t;

_ctx_t * _ctx = NULL;

void data_callback(ma_device* pDevice, void* pOutput, const void* pInput, ma_uint32 frame_count)
{
#ifdef MP_AUDIO_STREAM_DEBUG
    printf("callback: frameCount:%d start:%d end:%d\n", frame_count, _ctx->buf_start, _ctx->buf_end);
#endif
    float * out = (float *)pOutput;

    ma_uint32 plyable_size = _ctx->buf_end - _ctx->buf_start;
    ma_uint32 samples = frame_count * _ctx->channels;

    if (_ctx->is_exhaust && _ctx->exhaust_recover_size > plyable_size) {
        memset(out, 0, samples * sizeof(float));
        _ctx->exhaust_count++;
        return;
    }

    _ctx->is_exhaust = false;
    if (plyable_size < samples) {
        // copy the buffer to the output, and fill the rest
        memcpy(out, &_ctx->buf[_ctx->buf_start], plyable_size * sizeof(float));
        memset(&out[plyable_size], 0, (samples - plyable_size) * sizeof(float));

        _ctx->buf_start = _ctx->buf_end;
        _ctx->is_exhaust = true;
        _ctx->exhaust_count++;
    } else {
        memcpy(out, &_ctx->buf[_ctx->buf_start], samples * sizeof(float));
        _ctx->buf_start += samples;
    }
}

int ma_buffer_size() {
  return _ctx->buf_size;
}

int ma_buffer_filled_size() {
  return _ctx->buf_end - _ctx->buf_start;
}

int ma_stream_push(float* buf, int length) {
#ifdef MP_AUDIO_STREAM_DEBUGB
    printf("push: length:%d _length:%d _start:%d\n", length, _ctx->buf_end, _ctx->buf_start);
    for (int i=0; i<100; i+=10) {
        for (int j=0; j<10; j++) {
            unsigned char *b = (unsigned char *)(&buf[i+j]);
            printf("%02x%02x%02x%02x %f ", *(b+3), *(b+2), *(b+1), *(b+0), buf[i+j]);
        }
        printf("\n");
    }
    fflush(stdout);
#endif

    // ignore if no buffer remains
    if (_ctx->buf_end - _ctx->buf_start + length > _ctx->buf_size) {
        _ctx->full_count++;
        return -1;
    }

    // move the waiting buffer to the head of the buffer, if needed
    if (_ctx->buf_end + length > _ctx->buf_size) {
        memcpy(_ctx->buf, &_ctx->buf[_ctx->buf_start], (_ctx->buf_end - _ctx->buf_start)*sizeof(float));
        _ctx->buf_end -= _ctx->buf_start;
        _ctx->buf_start = 0;
    }

    memcpy(&_ctx->buf[_ctx->buf_end], buf, length * sizeof(float));

    _ctx->buf_end += length;

    return 0;
}

ma_uint32 ma_stream_stat_exhaust_count() {
    return _ctx->exhaust_count;
}

ma_uint32 ma_stream_stat_full_count() {
    return _ctx->full_count;
}

void ma_stream_stat_reset() {
    _ctx->full_count = 0;
    _ctx->exhaust_count = 0;
}

void ma_stream_uninit() {
    ma_device_uninit(&_ctx->device);
}

int ma_stream_init(int max_buffer_size, int keep_buffer_size, int channels, int sample_rate)
{
    if (_ctx == NULL) {
        _ctx = (_ctx_t *)calloc(1,sizeof(_ctx_t));

        _ctx->buf_size = 128 * 1024;
        _ctx->buf = NULL;
        _ctx->buf_end = 0;
        _ctx->buf_start = 0;
        _ctx->is_exhaust = false;
        _ctx->exhaust_recover_size = 10 * 1024;
        _ctx->exhaust_count = 0;
        _ctx->full_count = 0;
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

    _ctx->buf_size = max_buffer_size;
    _ctx->exhaust_recover_size = keep_buffer_size;

    if (_ctx->buf != NULL) {
        free(_ctx->buf);
    }

    _ctx->buf = (float *)calloc(_ctx->buf_size, sizeof(float));
    _ctx->buf_end = 0;
    _ctx->buf_start = 0;

    _ctx->channels = channels;

    if (ma_device_start(&_ctx->device) != MA_SUCCESS) {
        printf("Failed to start playback device.\n");
        ma_device_uninit(&_ctx->device);
        return -5;
    }

    return 0;
}
