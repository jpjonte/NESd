#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cmath>
#include <chrono>
#include <thread>

#include "./miniaudio/miniaudio.h"

#include "mp_audio_stream.h"

// macos
// cc -o test.out test.cc mp_audio_stream.cc -lstdc++

int main()
{
  ma_stream_init(128 * 1024, 2 * 1024, 1, 44100);

  int bufLength = 44100;

  float *buf = (float *)calloc(bufLength, sizeof(float));

  for (int freq = 440; freq < 441; freq += 5)
  {
    for (int j = 0; j < bufLength; j++)
    {
      buf[j] = (float)sin(2 * 3.14159265 * ((j * freq) % 44100) / 44100);
    }
    ma_stream_push(buf, bufLength);
    std::this_thread::sleep_for(std::chrono::milliseconds(200));
  }
  free(buf);

  puts("push any key to exit:");
  getchar();

  ma_stream_uninit();
}
