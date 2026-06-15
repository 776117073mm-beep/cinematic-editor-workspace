// native/cpp/engine/include/cinematic_engine.h
#pragma once
#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef int64_t SessionHandle;

typedef struct {
    int32_t success;
    int32_t error_code;
    char    error_message[512];
    double  progress;
} OperationResult;

typedef struct {
    float temperature, tint, brightness, contrast;
    float saturation, shadows, highlights, vibrance;
    float hue_shift, vignette, film_grain, sharpness;
} ColorGradeParams;

typedef struct {
    double duration;
    int32_t width, height;
    double frame_rate;
    int32_t has_audio;
    double audio_sample_rate;
    int32_t audio_channels;
    char video_codec[32];
    char audio_codec[32];
    int64_t file_size_bytes;
} VideoInfo;

typedef void (*ProgressCallback)(double progress, void* user_data);

SessionHandle     CE_CreateSession();
void              CE_DestroySession(SessionHandle session);
const char*       CE_GetVersion();
OperationResult   CE_GetVideoInfo(SessionHandle s, const char* path, VideoInfo* out);
OperationResult   CE_ExtractThumbnail(SessionHandle s, const char* vp, double ts, const char* op, int32_t w, int32_t h);
OperationResult   CE_GenerateProxy(SessionHandle s, const char* src, const char* dst, ProgressCallback cb, void* ud);
OperationResult   CE_ApplyColorGrade(SessionHandle s, const char* in, const char* out, ColorGradeParams p, double t0, double t1, ProgressCallback cb, void* ud);
OperationResult   CE_ConcatenateClips(SessionHandle s, const char** paths, int32_t n, const double* starts, const double* ends, const char* out, ProgressCallback cb, void* ud);
OperationResult   CE_MixAudioTracks(SessionHandle s, const char* vid, const char** aud, const float* vols, const double* starts, int32_t n, const char* out, ProgressCallback cb, void* ud);
OperationResult   CE_ChangeSpeed(SessionHandle s, const char* in, const char* out, double factor, int32_t pitch, ProgressCallback cb, void* ud);

#ifdef __cplusplus
}
#endif
