# The Flutter tooling requires that developers have CMake 3.10 or
# later installed. Do not increase this version.
cmake_minimum_required(VERSION 3.10)

project(nesd_audio_library VERSION 0.1.0 LANGUAGES CXX)

add_library(nesd_audio SHARED
  "nesd_audio.cc"
  "backend_miniaudio.cc"
)

set_target_properties(nesd_audio PROPERTIES
  PUBLIC_HEADER nesd_audio.h
  OUTPUT_NAME "nesd_audio"
)

if (ANDROID)
  # Support Android 15 16k page size.
  target_link_options(nesd_audio PRIVATE
    "-Wl,-z,max-page-size=16384")
endif()

# Host-only tests, built by bin/build_test_libs.sh; never enabled by
# the Flutter platform builds.
option(NESD_AUDIO_BUILD_TESTS "Build host-only native tests" OFF)

if (NESD_AUDIO_BUILD_TESTS)
  add_executable(spsc_ring_test spsc_ring_test.cc)

  find_package(Threads REQUIRED)
  target_link_libraries(spsc_ring_test PRIVATE Threads::Threads)
endif()
