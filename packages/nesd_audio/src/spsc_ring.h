#ifndef SPSC_RING_H_
#define SPSC_RING_H_

#include <atomic>
#include <cstdint>
#include <cstdlib>
#include <cstring>

// Single-producer single-consumer lock-free ring buffer for float samples.
// Producer: ma_stream_push (Dart thread). Consumer: miniaudio data callback.
// head/tail are monotonically increasing sample counts; the power-of-two
// capacity turns them into indices with a mask. logical_size (the requested
// buffer size) caps the fill level so external semantics match the old code.
typedef struct spsc_ring {
    float* buf;
    uint32_t mask;          // capacity - 1; capacity is a power of two
    uint32_t logical_size;  // externally visible capacity in samples
    std::atomic<uint64_t> head;  // total samples written (producer-owned)
    std::atomic<uint64_t> tail;  // total samples read (consumer-owned)
} spsc_ring_t;

static inline uint32_t spsc_pow2_at_least(uint32_t n) {
    uint32_t p = 1;
    while (p < n) {
        p <<= 1;
    }
    return p;
}

static inline void spsc_init(spsc_ring_t* ring, uint32_t size) {
    uint32_t capacity = spsc_pow2_at_least(size);
    ring->buf = (float*)calloc(capacity, sizeof(float));
    ring->mask = capacity - 1;
    ring->logical_size = size;
    ring->head.store(0, std::memory_order_relaxed);
    ring->tail.store(0, std::memory_order_relaxed);
}

static inline void spsc_destroy(spsc_ring_t* ring) {
    free(ring->buf);
    ring->buf = NULL;
}

// Atomic loads make this UB-free from any thread, but the snapshot is
// only meaningful from the producer or consumer thread (each owns one
// counter, so the difference cannot underflow there).
static inline uint32_t spsc_filled(const spsc_ring_t* ring) {
    uint64_t head = ring->head.load(std::memory_order_acquire);
    uint64_t tail = ring->tail.load(std::memory_order_acquire);
    return (uint32_t)(head - tail);
}

// Producer only. Returns 0 on success, -1 if the data does not fit.
static inline int spsc_push(spsc_ring_t* ring, const float* data,
                            uint32_t length) {
    uint64_t head = ring->head.load(std::memory_order_relaxed);
    uint64_t tail = ring->tail.load(std::memory_order_acquire);

    if ((uint32_t)(head - tail) + length > ring->logical_size) {
        return -1;
    }

    uint32_t capacity = ring->mask + 1;
    uint32_t index = (uint32_t)(head & ring->mask);
    uint32_t first = capacity - index;
    if (first > length) {
        first = length;
    }

    memcpy(&ring->buf[index], data, first * sizeof(float));
    memcpy(ring->buf, data + first, (length - first) * sizeof(float));

    ring->head.store(head + length, std::memory_order_release);
    return 0;
}

// Consumer only. Copies up to `length` samples into out, returns the count.
static inline uint32_t spsc_pop(spsc_ring_t* ring, float* out,
                                uint32_t length) {
    uint64_t head = ring->head.load(std::memory_order_acquire);
    uint64_t tail = ring->tail.load(std::memory_order_relaxed);

    uint32_t available = (uint32_t)(head - tail);
    uint32_t count = available < length ? available : length;

    uint32_t capacity = ring->mask + 1;
    uint32_t index = (uint32_t)(tail & ring->mask);
    uint32_t first = capacity - index;
    if (first > count) {
        first = count;
    }

    memcpy(out, &ring->buf[index], first * sizeof(float));
    memcpy(out + first, ring->buf, (count - first) * sizeof(float));

    ring->tail.store(tail + count, std::memory_order_release);
    return count;
}

#endif  // SPSC_RING_H_
