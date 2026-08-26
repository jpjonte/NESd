// Host-only test for the nesd_audio core (nesd_audio.cc) against a
// fake backend that captures the render callback, so the OS-audio-
// thread consumer path runs deterministically on the test thread.
#include "nesd_audio.h"

#include <cstdio>
#include <cstring>
#include <vector>

#include "nesd_audio_backend.h"

// --- Fake backend ---------------------------------------------------

struct nesd_audio_backend {
    nesd_audio_render_cb render;
    void *user;
};

static nesd_audio_backend_t g_backend;

nesd_audio_backend_t *nesd_audio_backend_open(
    int32_t sample_rate, int32_t channels, bool null_device,
    nesd_audio_render_cb render, void *user) {
    (void)sample_rate;
    (void)channels;
    (void)null_device;

    g_backend.render = render;
    g_backend.user = user;

    return &g_backend;
}

void nesd_audio_backend_close(nesd_audio_backend_t *backend) {
    (void)backend;
}

bool nesd_audio_backend_is_null_device(nesd_audio_backend_t *backend) {
    (void)backend;
    return false;
}

uint32_t nesd_audio_backend_ensure_running(nesd_audio_backend_t *backend) {
    (void)backend;
    return 0;
}

// --- Harness --------------------------------------------------------

static int g_failures = 0;

#define CHECK(cond)                                              \
    do {                                                         \
        if (!(cond)) {                                           \
            printf("FAIL %s:%d: %s\n", __FILE__, __LINE__,       \
                   #cond);                                       \
            g_failures++;                                        \
        }                                                        \
    } while (0)

static void render(nesd_audio_t *stream, float *out, int32_t samples) {
    (void)stream;
    g_backend.render(g_backend.user, out, samples);
}

static void push_seq(nesd_audio_t *stream, float first, int32_t count) {
    std::vector<float> data((size_t)count);

    for (int32_t i = 0; i < count; i++) {
        data[(size_t)i] = first + (float)i;
    }

    CHECK(nesd_audio_push(stream, data.data(), count) == count);
}

static bool is_seq(const float *data, float first, int32_t count) {
    for (int32_t i = 0; i < count; i++) {
        if (data[i] != first + (float)i) {
            return false;
        }
    }

    return true;
}

static bool is_silence(const float *data, int32_t count) {
    for (int32_t i = 0; i < count; i++) {
        if (data[i] != 0.0f) {
            return false;
        }
    }

    return true;
}

static nesd_audio_t *open_stream() {
    return nesd_audio_open(48000, 1, 2400, 960, 0);
}

// --- Tests ----------------------------------------------------------

static void test_pop_copies_data_in_order() {
    nesd_audio_t *stream = open_stream();
    std::vector<float> out(480);

    push_seq(stream, 1.0f, 960);

    render(stream, out.data(), 480);
    CHECK(is_seq(out.data(), 1.0f, 480));

    render(stream, out.data(), 480);
    CHECK(is_seq(out.data(), 481.0f, 480));

    CHECK(nesd_audio_underruns(stream) == 0);

    nesd_audio_close(stream);
}

static void test_short_pop_pads_silence_and_counts_underrun() {
    nesd_audio_t *stream = open_stream();
    std::vector<float> out(480);

    push_seq(stream, 1.0f, 300);

    render(stream, out.data(), 480);
    CHECK(is_seq(out.data(), 1.0f, 300));
    CHECK(is_silence(out.data() + 300, 180));
    CHECK(nesd_audio_underruns(stream) == 1);

    nesd_audio_close(stream);
}

static void test_recovery_holds_silence_until_pop_plus_runway() {
    nesd_audio_t *stream = open_stream();
    std::vector<float> out(480);

    // trigger an underrun on an empty ring
    // 480 pop + 960 margin -> 1440 recovery target
    render(stream, out.data(), 480);
    CHECK(nesd_audio_underruns(stream) == 1);

    // below target: silence, ring untouched
    push_seq(stream, 1.0f, 1400);
    render(stream, out.data(), 480);
    CHECK(is_silence(out.data(), 480));
    CHECK(nesd_audio_filled(stream) == 1400);

    // at target: playback resumes
    push_seq(stream, 1401.0f, 40);
    render(stream, out.data(), 480);
    CHECK(is_seq(out.data(), 1.0f, 480));

    nesd_audio_close(stream);
}

static void test_recovery_adapts_to_large_pops() {
    nesd_audio_t *stream = open_stream();
    std::vector<float> out(1700);

    push_seq(stream, 1.0f, 2400);

    render(stream, out.data(), 1700);
    CHECK(is_seq(out.data(), 1.0f, 1700));

    // only 700 left, trigger underrun
    render(stream, out.data(), 1700);
    CHECK(nesd_audio_underruns(stream) == 1);

    // refill below target: must stay silent
    push_seq(stream, 1.0f, 1900);
    render(stream, out.data(), 1700);
    CHECK(is_silence(out.data(), 1700));
    CHECK(nesd_audio_filled(stream) == 1900);

    // at target: playback resumes
    push_seq(stream, 1901.0f, 500);
    render(stream, out.data(), 1700);
    CHECK(is_seq(out.data(), 1.0f, 1700));

    nesd_audio_close(stream);
}

static void test_recovery_target_clamps_to_capacity() {
    nesd_audio_t *stream = open_stream();
    std::vector<float> out(3000);

    render(stream, out.data(), 3000);
    CHECK(nesd_audio_underruns(stream) == 1);

    push_seq(stream, 1.0f, 2400);
    render(stream, out.data(), 480);
    CHECK(is_seq(out.data(), 1.0f, 480));

    nesd_audio_close(stream);
}

static void test_reset_stats_keeps_recovery_watermark() {
    nesd_audio_t *stream = open_stream();
    std::vector<float> out(1700);

    push_seq(stream, 1.0f, 1700);
    render(stream, out.data(), 1700);
    render(stream, out.data(), 480);
    CHECK(nesd_audio_underruns(stream) == 1);

    nesd_audio_reset_stats(stream);

    push_seq(stream, 1.0f, 2000);
    render(stream, out.data(), 480);
    CHECK(is_silence(out.data(), 480));
    CHECK(nesd_audio_filled(stream) == 2000);

    nesd_audio_close(stream);
}

int main() {
    test_pop_copies_data_in_order();
    test_short_pop_pads_silence_and_counts_underrun();
    test_recovery_holds_silence_until_pop_plus_runway();
    test_recovery_adapts_to_large_pops();
    test_recovery_target_clamps_to_capacity();
    test_reset_stats_keeps_recovery_watermark();

    if (g_failures > 0) {
        printf("FAILED: %d check(s)\n", g_failures);
        return 1;
    }

    printf("OK: nesd_audio core tests passed\n");
    return 0;
}
