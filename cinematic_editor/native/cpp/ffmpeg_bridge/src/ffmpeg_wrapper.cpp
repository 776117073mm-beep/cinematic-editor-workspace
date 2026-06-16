#include "../include/ffmpeg_wrapper.h"

bool FFmpegWrapper_Initialize() {
    // Placeholder implementation for Android NDK build.
    // In a full implementation, initialize FFmpeg libraries via JNI or native APIs.
    return true;
}

void FFmpegWrapper_Shutdown() {
    // Placeholder shutdown path.
}

const char* FFmpegWrapper_Version() {
    return "ffmpeg_wrapper-placeholder-1.0";
}
