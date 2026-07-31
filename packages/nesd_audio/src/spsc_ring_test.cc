// Host-only stress test for spsc_ring.h. Build & run:
//   clang++ -std=c++17 -O1 -g -fsanitize=thread -pthread \
//     spsc_ring_test.cc -o spsc_ring_test.out && ./spsc_ring_test.out
#include "spsc_ring.h"

#include <cstdio>
#include <thread>
#include <vector>

int main() {
    spsc_ring_t ring;
    spsc_init(&ring, 2400);

    const uint32_t total = 5000000;  // < 2^24, exactly representable

    std::thread producer([&] {
        std::vector<float> chunk;
        uint32_t sent = 0;
        uint32_t chunk_size = 1;
        while (sent < total) {
            chunk_size = chunk_size % 800 + 7;
            uint32_t n = chunk_size;
            if (sent + n > total) n = total - sent;
            chunk.resize(n);
            for (uint32_t i = 0; i < n; i++) chunk[i] = (float)(sent + i);
            while (spsc_push(&ring, chunk.data(), n) != 0) {
                std::this_thread::yield();
            }
            sent += n;
        }
    });

    std::vector<float> out(1024);
    uint64_t received = 0;
    while (received < total) {
        uint32_t n = spsc_pop(&ring, out.data(), (uint32_t)out.size());
        for (uint32_t i = 0; i < n; i++) {
            if (out[i] != (float)(received + i)) {
                printf("FAIL at sample %llu\n",
                       (unsigned long long)(received + i));
                return 1;
            }
        }
        received += n;
        if (n == 0) std::this_thread::yield();
    }

    producer.join();
    spsc_destroy(&ring);
    printf("OK: %llu samples in order\n", (unsigned long long)received);
    return 0;
}
