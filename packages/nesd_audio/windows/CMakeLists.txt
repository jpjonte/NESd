# The Flutter tooling requires that developers have CMake 3.10 or
# later installed. Do not increase this version.
cmake_minimum_required(VERSION 3.10)

set(PROJECT_NAME "nesd_audio")
project(${PROJECT_NAME} LANGUAGES CXX)

# Invoke the build for native code shared with the other platforms.
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../src"
  "${CMAKE_CURRENT_BINARY_DIR}/shared")

# Libraries bundled with the plugin; defined in ../src/CMakeLists.txt.
set(nesd_audio_bundled_libraries
  $<TARGET_FILE:nesd_audio>
  PARENT_SCOPE
)
