// lib/features/export/services/ffmpeg_executor.dart
//
// ════════════════════════════════════════════════════════════════════════════
// الربط الحقيقي والكامل بين Flutter و FFmpegKit
//
// المكتبة المستخدمة:  ffmpeg_kit_flutter_full_gpl
// التوثيق الرسمي:     https://github.com/arthenica/ffmpeg-kit
//
// كيف تعمل:
//   1. نبني سلسلة الأوامر كـ String (مثل سطر أوامر linux)
//   2. نمررها إلى FFmpegKit.execute()
//   3. نستقبل ReturnCode ونتحقق من النجاح
//   4. للعمليات الطويلة نستخدم FFmpegKit.executeAsync()
//      مع Statistics callback لتحديث شريط التقدم
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/statistics.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/log.dart';

/// نتيجة تنفيذ أمر FFmpeg
class FFmpegResult {
  final bool success;
  final int returnCode;
  final String? errorOutput;
  final Duration executionTime;

  const FFmpegResult({
    required this.success,
    required this.returnCode,
    this.errorOutput,
    required this.executionTime,
  });

  @override
  String toString() =>
      'FFmpegResult(success:$success, rc:$returnCode, time:$executionTime)';
}

/// معلومات تقدم التشفير
class FFmpegProgress {
  final double progress;      // 0.0 → 1.0
  final int framesEncoded;
  final double fps;
  final double speed;         // 1.0 = real-time, 2.0 = ضعف السرعة
  final int bitrateKbps;

  const FFmpegProgress({
    required this.progress,
    required this.framesEncoded,
    required this.fps,
    required this.speed,
    required this.bitrateKbps,
  });
}

// ════════════════════════════════════════════════════════════════════════════
// الكلاس الرئيسي
// ════════════════════════════════════════════════════════════════════════════
class FFmpegExecutor {

  /// ── تهيئة FFmpegKit عند بدء التطبيق ──────────────────────────────────
  static Future<void> initialize() async {
    // تفعيل logs فقط في وضع التطوير
    FFmpegKitConfig.enableLogCallback((Log log) {
      // ignore: avoid_print
      assert(() {
        // ignore: avoid_print
        print('[FFmpeg] ${log.getMessage()}');
        return true;
      }());
    });
    // إيقاف Statistics في وضع الإنتاج ← سيُفعَّل عند executeAsync
    FFmpegKitConfig.enableStatisticsCallback(null);
  }

  // ──────────────────────────────────────────────────────────────────────────
  /// تنفيذ أمر بسيط وانتظر اكتماله (مُزامَن)
  // ──────────────────────────────────────────────────────────────────────────
  static Future<FFmpegResult> execute(String command) async {
    final stopwatch = Stopwatch()..start();

    final session = await FFmpegKit.execute(command);
    final rc      = await session.getReturnCode();
    final logs    = await session.getAllLogsAsString();

    stopwatch.stop();

    return FFmpegResult(
      success:       ReturnCode.isSuccess(rc),
      returnCode:    rc?.getValue() ?? -1,
      errorOutput:   ReturnCode.isSuccess(rc) ? null : logs,
      executionTime: stopwatch.elapsed,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  /// تنفيذ أمر مع تحديث تقدم لحظي (للتصدير الطويل)
  ///
  /// [totalDurationMs] المدة الكلية للفيديو بالمللي ثانية
  ///                   (نحصل عليها مسبقاً لحساب نسبة التقدم)
  // ──────────────────────────────────────────────────────────────────────────
  static Stream<FFmpegProgress> executeWithProgress({
    required String command,
    required double totalDurationMs,
  }) async* {
    final progressController = StreamController<FFmpegProgress>();

    // Statistics callback يُستدعى كل ~1 ثانية من FFmpegKit
    FFmpegKitConfig.enableStatisticsCallback((Statistics stats) {
      if (progressController.isClosed) return;

      // الوقت المُعالَج حتى الآن (مللي ثانية)
      final processedMs = stats.getTime().toDouble();
      final progress    = totalDurationMs > 0
          ? (processedMs / totalDurationMs).clamp(0.0, 0.99)
          : 0.0;

      progressController.add(FFmpegProgress(
        progress:       progress,
        framesEncoded:  stats.getVideoFrameNumber(),
        fps:            stats.getVideoFps(),
        speed:          stats.getSpeed(),
        bitrateKbps:    (stats.getBitrate() / 1000).round(),
      ));
    });

    // تنفيذ الأمر بشكل غير متزامن
    FFmpegKit.executeAsync(
      command,
      (FFmpegSession completedSession) async {
        final rc = await completedSession.getReturnCode();

        if (ReturnCode.isSuccess(rc)) {
          // أرسل 100% عند الاكتمال
          progressController.add(const FFmpegProgress(
            progress: 1.0, framesEncoded: 0, fps: 0, speed: 0, bitrateKbps: 0,
          ));
        } else {
          final logs = await completedSession.getAllLogsAsString();
          progressController.addError(
            FFmpegExecutionException('FFmpeg failed (rc=${rc?.getValue()}): $logs'),
          );
        }

        FFmpegKitConfig.enableStatisticsCallback(null); // أوقف callback
        await progressController.close();
      },
    );

    yield* progressController.stream;
  }

  // ──────────────────────────────────────────────────────────────────────────
  /// إلغاء كل العمليات الجارية
  // ──────────────────────────────────────────────────────────────────────────
  static Future<void> cancelAll() async {
    await FFmpegKit.cancel();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // دوال بناء أوامر FFmpeg الجاهزة
  // ──────────────────────────────────────────────────────────────────────────

  /// قص مقطع (copy بدون إعادة ترميز - سريع جداً)
  static String buildTrimCommand({
    required String input,
    required String output,
    required double startSec,
    required double endSec,
  }) {
    final dur = endSec - startSec;
    return '-ss ${startSec.toStringAsFixed(6)} '
        '-i "$input" '
        '-t ${dur.toStringAsFixed(6)} '
        '-c copy -avoid_negative_ts make_zero '
        '-y "$output"';
  }

  /// دمج مقاطع من ملف قائمة (concat demuxer)
  static String buildConcatCommand({
    required String listFilePath,
    required String output,
    bool reEncode = false,
  }) {
    if (reEncode) {
      return '-f concat -safe 0 -i "$listFilePath" '
          '-c:v libx264 -crf 18 -preset fast '
          '-c:a aac -b:a 192k '
          '-movflags +faststart -y "$output"';
    }
    return '-f concat -safe 0 -i "$listFilePath" -c copy -y "$output"';
  }

  /// تصحيح الألوان عبر سلسلة فلاتر
  static String buildColorGradeCommand({
    required String input,
    required String output,
    required String filterChain,
  }) {
    return '-i "$input" -vf "$filterChain" -c:a copy '
        '-c:v libx264 -crf 18 -preset fast -y "$output"';
  }

  /// مزج مسارات صوتية متعددة
  static String buildAudioMixCommand({
    required String videoInput,
    required List<String> audioInputs,
    required List<double> volumes,
    required List<double> startTimesMs,
    required String output,
  }) {
    final inputs  = StringBuffer('-i "$videoInput"');
    final filters = StringBuffer('[0:a]volume=1.0[a0];');
    var   mix     = '[a0]';

    for (int i = 0; i < audioInputs.length; i++) {
      inputs.write(' -i "${audioInputs[i]}"');
      final vol   = volumes[i].toStringAsFixed(2);
      final delay = startTimesMs[i].round();
      if (delay > 0) {
        filters.write('[${i+1}:a]volume=$vol,adelay=${delay}|${delay}[a${i+1}];');
      } else {
        filters.write('[${i+1}:a]volume=$vol[a${i+1}];');
      }
      mix += '[a${i+1}]';
    }

    final amix = '${mix}amix=inputs=${audioInputs.length + 1}'
        ':duration=longest:normalize=0[aout]';

    return '$inputs '
        '-filter_complex "${filters}$amix" '
        '-map 0:v -map "[aout]" '
        '-c:v copy -c:a aac -b:a 192k -y "$output"';
  }

  /// إضافة نصوص بـ drawtext
  static String buildDrawtextCommand({
    required String input,
    required String output,
    required List<Map<String,dynamic>> textLayers,
  }) {
    final filters = textLayers.map((layer) {
      final text    = (layer['text'] as String)
          .replaceAll(':', r'\:').replaceAll("'", r"'");
      final fs      = layer['fontSize'] as int;
      final color   = layer['color'] as String;
      final x       = layer['x'] as String;
      final y       = layer['y'] as String;
      final tStart  = (layer['startTime'] as double).toStringAsFixed(3);
      final tEnd    = (layer['endTime']   as double).toStringAsFixed(3);
      final fadeIn  = (layer['startTime'] as double + 0.3).toStringAsFixed(3);
      final fadeOut = (layer['endTime']   as double - 0.3).toStringAsFixed(3);

      return "drawtext=text='$text'"
          ":fontsize=$fs:fontcolor=$color"
          ":x=$x:y=$y"
          ":enable='between(t,$tStart,$tEnd)'"
          ":alpha='if(lt(t,$fadeIn),(t-$tStart)/0.3,if(gt(t,$fadeOut),($tEnd-t)/0.3,1))'"
          ":box=1:boxcolor=black@0.4:boxborderw=6";
    }).join(',');

    return '-i "$input" -vf "$filters" -c:a copy '
        '-c:v libx264 -crf 18 -preset fast -y "$output"';
  }

  /// التشفير النهائي (جودة عالية)
  static String buildFinalEncodeCommand({
    required String input,
    required String output,
    required String resolution,
    required double frameRate,
    required int videoBitrateKbps,
    required int audioBitrateKbps,
    bool useHevc = false,
  }) {
    final codec = useHevc ? 'libx265' : 'libx264';

    final scaleMap = {
      '4K':   'scale=3840:2160:flags=lanczos',
      '1080p':'scale=1920:1080:flags=lanczos',
      '720p': 'scale=1280:720:flags=lanczos',
      '480p': 'scale=854:480:flags=lanczos',
    };
    final scale = scaleMap[resolution] ?? scaleMap['1080p']!;
    final fps   = frameRate.toStringAsFixed(0);

    return '-i "$input" '
        '-vf "$scale,fps=$fps" '
        '-c:v $codec '
        '-b:v ${videoBitrateKbps}k '
        '-preset slow -profile:v high '
        '-c:a aac -b:a ${audioBitrateKbps}k '
        '-movflags +faststart '
        '-y "$output"';
  }

  /// تغيير سرعة مقطع
  static String buildSpeedCommand({
    required String input,
    required String output,
    required double speedFactor,
    bool pitchCorrection = true,
  }) {
    final pts    = (1.0 / speedFactor).toStringAsFixed(6);
    final vf     = 'setpts=$pts*PTS';

    // atempo يعمل فقط بين 0.5 و 2.0 - نسلسل عدة مراحل للقيم الأكبر
    String af = _buildAtempoChain(speedFactor);

    return '-i "$input" -vf "$vf" -af "$af" '
        '-c:v libx264 -crf 18 -preset fast -y "$output"';
  }

  /// إنشاء Proxy 360p سريع
  static String buildProxyCommand({
    required String input,
    required String output,
  }) {
    return '-i "$input" '
        '-vf "scale=640:360:force_original_aspect_ratio=decrease,'
        'pad=640:360:(ow-iw)/2:(oh-ih)/2" '
        '-c:v libx264 -crf 28 -preset veryfast '
        '-profile:v baseline -level 3.1 '
        '-c:a aac -b:a 64k '
        '-movflags +faststart -y "$output"';
  }

  /// استخراج صورة مصغرة
  static String buildThumbnailCommand({
    required String input,
    required String output,
    required double timestampSec,
    int width  = 320,
    int height = 180,
  }) {
    return '-ss ${timestampSec.toStringAsFixed(3)} '
        '-i "$input" '
        '-vframes 1 '
        '-vf "scale=$width:$height:force_original_aspect_ratio=decrease" '
        '-y "$output"';
  }

  /// تثبيت الصورة (two-pass)
  static String buildStabilizeAnalyzeCommand({
    required String input,
    required String transformsFile,
  }) =>
      '-i "$input" -vf "vidstabdetect=stepsize=6:shakiness=8:accuracy=9:'
      'result=$transformsFile" -f null -';

  static String buildStabilizeApplyCommand({
    required String input,
    required String output,
    required String transformsFile,
  }) =>
      '-i "$input" -vf "vidstabtransform=input=$transformsFile:'
      'zoom=1:smoothing=30,unsharp=5:5:0.8:3:3:0.4" '
      '-c:a copy -y "$output"';

  // ────────────── helpers ──────────────────────────────────────────────────

  static String _buildAtempoChain(double speed) {
    if (speed >= 0.5 && speed <= 2.0) return 'atempo=$speed';
    final parts = <String>[];
    double remaining = speed;
    if (speed > 2.0) {
      while (remaining > 2.0) { parts.add('atempo=2.0'); remaining /= 2.0; }
      if (remaining > 1.001) parts.add('atempo=${remaining.toStringAsFixed(4)}');
    } else {
      while (remaining < 0.5) { parts.add('atempo=0.5'); remaining /= 0.5; }
      if (remaining < 0.999) parts.add('atempo=${remaining.toStringAsFixed(4)}');
    }
    return parts.join(',');
  }
}

class FFmpegExecutionException implements Exception {
  final String message;
  const FFmpegExecutionException(this.message);
  @override String toString() => 'FFmpegExecutionException: $message';
}
