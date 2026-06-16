#pragma once

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

bool FFmpegWrapper_Initialize();
void FFmpegWrapper_Shutdown();
const char* FFmpegWrapper_Version();

#ifdef __cplusplus
}
#endif
