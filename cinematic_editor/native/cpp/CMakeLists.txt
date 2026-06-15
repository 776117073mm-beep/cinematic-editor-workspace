cmake_minimum_required(VERSION 3.22)
project(cinematic_engine VERSION 1.0.0 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG")

if(ANDROID)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mfpu=neon")
endif()

add_library(cinematic_engine SHARED
    engine/src/cinematic_engine.cpp
    ffmpeg_bridge/src/ffmpeg_wrapper.cpp
)

target_include_directories(cinematic_engine PRIVATE
    engine/include/
    ffmpeg_bridge/include/
)

if(ANDROID)
    find_library(log-lib log)
    find_library(android-lib android)
    target_link_libraries(cinematic_engine ${log-lib} ${android-lib}
        avcodec avformat avfilter avutil swscale swresample)
endif()
