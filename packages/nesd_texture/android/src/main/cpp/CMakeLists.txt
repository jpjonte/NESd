cmake_minimum_required(VERSION 3.22.1)

project(nesd_texture_native LANGUAGES CXX)

add_library(nesd_texture_native SHARED
    native_bindings.cpp
)

find_library(log-lib log)
find_library(jnigraphics-lib jnigraphics)

target_link_libraries(
    nesd_texture_native
    ${log-lib}
    ${jnigraphics-lib}
)
