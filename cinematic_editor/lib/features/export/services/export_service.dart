// lib/features/export/services/export_service.dart
//
// نظام التصدير الكامل - مربوط بـ FFmpegKit عبر FFmpegExecutor
// الترتيب:
//   validate → prepare → process each clip → concat → mix audio
//             → render text → final encode → cleanup

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_lib;
import 'package:flutter/services.dart';

import 'ffmpeg_executor.dart';
import '../models/export_models.dart';
import '../../subscription/services/device_security_service.dart';
import '../../../core/models/timeline_models.dart';

class ExportService {
  final DeviceSecurityService _deviceSecurity;

  ExportService({required DeviceSecurityService deviceSecurity})
      : _deviceSecurity = deviceSecurity;

  // ══════════════════════════════════════════════════════════════════════════
  // نقطة الدخول الرئيسية
  // ══════════════════════════════════════════════════════════════════════════
  Stream<ExportProgress> exportProject({
    required TimelineState timelineState,
    required ExportSettings settings,
    required String outputFileName,
  }) async* {

    final sw = Stopwatch()..start();

    // ── 0. التحقق من الصلاحية ─────────────────────────────────────────────
    yield ExportProgress.stage(stage: ExportStage.validating, progress: 0.0);

    final perm = await _deviceSecurity.checkExportPermission(
      resolution: settings.resolution,
      hasSubscription: settings.hasSubscription,
    );
    if (!perm.isAllowed) {
      yield ExportProgress.failed(error: perm.denialReason ?? 'غير مسموح');
      return;
    }

    // ── 1. إعداد مجلد العمل ───────────────────────────────────────────────
    yield ExportProgress.stage(stage: ExportStage.preparing, progress: 0.02);
    final workDir = await _createWorkDir();

    // ── 2. حفظ JSON للتايم لاين ───────────────────────────────────────────
    yield ExportProgress.stage(stage: ExportStage.preparing, progress: 0.04);
    final tlJsonPath = '${workDir.path}/timeline.json';
    await File(tlJsonPath).writeAsString(
        json.encode(timelineState.toJson()), flush: true);

    // ── 3. معالجة كل مقطع ────────────────────────────────────────────────
    yield ExportProgress.stage(stage: ExportStage.processingClips, progress: 0.05);
    final processedPaths = <String>[];
    final clips = timelineState.videoClips
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    for (int i = 0; i < clips.length; i++) {
      yield ExportProgress(
        stage: ExportStage.processingClips,
        progress: 0.05 + (i / clips.length) * 0.48,
        currentClipIndex: i,
        totalClips: clips.length,
        currentClipName: path_lib.basename(clips[i].originalPath),
        elapsedSeconds: sw.elapsed.inSeconds,
      );
      final p = await _processClip(clip: clips[i], workDir: workDir);
      processedPaths.add(p);
    }

    // ── 4. دمج المقاطع ────────────────────────────────────────────────────
    yield ExportProgress.stage(stage: ExportStage.concatenating, progress: 0.54);
    final concatPath = '${workDir.path}/concat.mp4';
    await _concatClips(processedPaths, concatPath, timelineState);

    // ── 5. مزج الصوت ─────────────────────────────────────────────────────
    yield ExportProgress.stage(stage: ExportStage.mixingAudio, progress: 0.67);
    final mixedPath = '${workDir.path}/mixed.mp4';
    await _mixAudio(concatPath, timelineState.audioClips, mixedPath);

    // ── 6. رسم النصوص ────────────────────────────────────────────────────
    yield ExportProgress.stage(stage: ExportStage.addingText, progress: 0.77);
    final textedPath = '${workDir.path}/texted.mp4';
    await _renderText(mixedPath, timelineState.textLayers, textedPath, settings);

    // ── 7. التشفير النهائي ────────────────────────────────────────────────
    yield ExportProgress.stage(stage: ExportStage.encoding, progress: 0.83);
    final finalPath = await _buildOutputPath(outputFileName, settings.resolution);

    final totalMs = timelineState.totalDuration * 1000;
    await for (final p in FFmpegExecutor.executeWithProgress(
      command: FFmpegExecutor.buildFinalEncodeCommand(
        input:             textedPath,
        output:            finalPath,
        resolution:        settings.resolution,
        frameRate:         settings.frameRate,
        videoBitrateKbps:  settings.videoBitrateKbps,
        audioBitrateKbps:  settings.audioBitrateKbps,
        useHevc:           settings.resolution == '4K',
      ),
      totalDurationMs: totalMs,
    )) {
      yield ExportProgress(
        stage: ExportStage.encoding,
        progress: 0.83 + p.progress * 0.14,
        elapsedSeconds: sw.elapsed.inSeconds,
      );
    }

    // ── 8. تنظيف وإنهاء ──────────────────────────────────────────────────
    yield ExportProgress.stage(stage: ExportStage.finalizing, progress: 0.97);
    try { await workDir.delete(recursive: true); } catch (_) {}
    await _deviceSecurity.incrementExportCount(settings.resolution);

    sw.stop();
    final size = await File(finalPath).length();
    yield ExportProgress.completed(
      outputPath:    finalPath,
      fileSizeBytes: size,
      totalSeconds:  sw.elapsed.inSeconds,
      resolution:    settings.resolution,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // معالجة مقطع واحد (trim + effects)
  // ══════════════════════════════════════════════════════════════════════════
  Future<String> _processClip({
    required VideoClip clip,
    required Directory workDir,
  }) async {
    final clipDir = Directory('${workDir.path}/clip_${clip.id}');
    await clipDir.create();
    String cur = clip.originalPath;
    int step = 0;

    // ── Trim ──────────────────────────────────────────────────────────────
    if (clip.clipStartOffset > 0.01 || clip.contentDuration < clip.duration - 0.01) {
      final out = '${clipDir.path}/s${step++}_trim.mp4';
      final r = await FFmpegExecutor.execute(
        FFmpegExecutor.buildTrimCommand(
          input:    cur,
          output:   out,
          startSec: clip.clipStartOffset,
          endSec:   clip.clipEndOffset,
        ),
      );
      if (r.success) cur = out;
    }

    // ── Speed ─────────────────────────────────────────────────────────────
    if ((clip.speed - 1.0).abs() > 0.01) {
      final out = '${clipDir.path}/s${step++}_speed.mp4';
      final r = await FFmpegExecutor.execute(
        FFmpegExecutor.buildSpeedCommand(
          input:  cur,
          output: out,
          speedFactor: clip.speed,
        ),
      );
      if (r.success) cur = out;
    }

    // ── Effects ───────────────────────────────────────────────────────────
    for (final effect in clip.effects.where((e) => e.isEnabled)) {
      final out = '${clipDir.path}/s${step++}_${effect.type.name}.mp4';
      switch (effect.type) {

        case EffectType.colorGrade:
          final f = _buildColorGradeFilter(effect.parameters);
          final r = await FFmpegExecutor.execute(
            FFmpegExecutor.buildColorGradeCommand(
              input: cur, output: out, filterChain: f,
            ),
          );
          if (r.success) cur = out;

        case EffectType.blur:
          final sigma = ((effect.parameters['radius'] as num?)?.toDouble() ?? 5.0) * 2;
          final r = await FFmpegExecutor.execute(
            '-i "$cur" -vf "gblur=sigma=$sigma" -c:a copy -y "$out"',
          );
          if (r.success) cur = out;

        case EffectType.vignette:
          final str = (effect.parameters['strength'] as num?)?.toDouble() ?? 0.5;
          final angle = (str * 1.5708).toStringAsFixed(4);
          final r = await FFmpegExecutor.execute(
            '-i "$cur" -vf "vignette=angle=$angle" -c:a copy -y "$out"',
          );
          if (r.success) cur = out;

        case EffectType.stabilization:
          final trf = '$out.trf';
          await FFmpegExecutor.execute(
            FFmpegExecutor.buildStabilizeAnalyzeCommand(
              input: cur, transformsFile: trf,
            ),
          );
          final r = await FFmpegExecutor.execute(
            FFmpegExecutor.buildStabilizeApplyCommand(
              input: cur, output: out, transformsFile: trf,
            ),
          );
          if (r.success) cur = out;
          try { File(trf).deleteSync(); } catch (_) {}

        case EffectType.backgroundRemoval:
          // MediaPipe عبر Platform Channel
          await _applyBgRemoval(cur, out, effect.parameters);
          if (File(out).existsSync()) cur = out;

        default:
          break; // تجاهل التأثيرات غير المدعومة محلياً
      }
    }

    return cur;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // دمج المقاطع
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _concatClips(
    List<String> paths,
    String output,
    TimelineState tl,
  ) async {
    if (paths.isEmpty) return;
    if (paths.length == 1) { await File(paths.first).copy(output); return; }

    final tmpDir  = await getTemporaryDirectory();
    final listFile = File('${tmpDir.path}/concat_${DateTime.now().millisecondsSinceEpoch}.txt');
    await listFile.writeAsString(paths.map((p) => "file '${p.replaceAll("'","'\''")}'
").join());

    final r = await FFmpegExecutor.execute(
      FFmpegExecutor.buildConcatCommand(listFilePath: listFile.path, output: output),
    );
    try { listFile.deleteSync(); } catch (_) {}
    if (!r.success) throw ExportException('Concat failed: ${r.errorOutput}');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // مزج الصوت
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _mixAudio(
    String videoPath,
    List<AudioClip> audioClips,
    String output,
  ) async {
    if (audioClips.isEmpty) { await File(videoPath).copy(output); return; }

    final r = await FFmpegExecutor.execute(
      FFmpegExecutor.buildAudioMixCommand(
        videoInput:    videoPath,
        audioInputs:   audioClips.map((a) => a.filePath).toList(),
        volumes:       audioClips.map((a) => a.volume).toList(),
        startTimesMs:  audioClips.map((a) => a.startTime * 1000).toList(),
        output:        output,
      ),
    );
    if (!r.success) throw ExportException('Audio mix failed: ${r.errorOutput}');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // رسم النصوص
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _renderText(
    String videoPath,
    List<TextLayer> layers,
    String output,
    ExportSettings settings,
  ) async {
    if (layers.isEmpty) { await File(videoPath).copy(output); return; }

    final layerData = layers.map((l) {
      final colorHex =
          '0x${(l.style.color?.value ?? 0xFFFFFFFF).toRadixString(16).padLeft(8,'0').toUpperCase()}';
      return {
        'text':      l.text,
        'fontSize':  (l.style.fontSize ?? 24).toInt(),
        'color':     colorHex,
        'x':         '(w-text_w)/2',
        'y':         'h*${l.transform.y.toStringAsFixed(3)}',
        'startTime': l.startTime,
        'endTime':   l.endTime,
      };
    }).toList();

    final r = await FFmpegExecutor.execute(
      FFmpegExecutor.buildDrawtextCommand(
        input: videoPath, output: output, textLayers: layerData,
      ),
    );
    if (!r.success) throw ExportException('Text render failed: ${r.errorOutput}');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // إزالة الخلفية (MediaPipe عبر Platform Channel)
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _applyBgRemoval(
    String input, String output, Map<String,dynamic> params,
  ) async {
    const ch = MethodChannel('com.cinematiceditor/mediapipe');
    try {
      await ch.invokeMethod('startVideoSegmentation', {
        'input_path':       input,
        'output_path':      output,
        'replacement_type': params['replacement_type'] ?? 'TransparentBackground',
      });
    } catch (_) {
      // fallback: نسخ الملف بدون تأثير
      await File(input).copy(output);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // بناء فلتر تصحيح الألوان
  // ══════════════════════════════════════════════════════════════════════════
  String _buildColorGradeFilter(Map<String,dynamic> p) {
    final parts = <String>[];

    final brightness = (p['brightness'] as num?)?.toDouble() ?? 0.0;
    final contrast   = (p['contrast']   as num?)?.toDouble() ?? 0.0;
    final saturation = (p['saturation'] as num?)?.toDouble() ?? 0.0;
    if (brightness.abs() > 0.001 || contrast.abs() > 0.001 || saturation.abs() > 0.001) {
      parts.add('eq=brightness=$brightness:contrast=${1+contrast}:saturation=${1+saturation}');
    }

    final temperature = (p['temperature'] as num?)?.toDouble() ?? 0.0;
    if (temperature.abs() > 0.001) {
      final rg = (1.0 + temperature * 0.2).toStringAsFixed(4);
      final bg = (1.0 - temperature * 0.2).toStringAsFixed(4);
      parts.add('colorchannelmixer=rr=$rg:bb=$bg');
    }

    final shadows    = (p['shadows']    as num?)?.toDouble() ?? 0.0;
    final highlights = (p['highlights'] as num?)?.toDouble() ?? 0.0;
    if (shadows.abs() > 0.001 || highlights.abs() > 0.001) {
      final p0  = (shadows * 0.1).clamp(-0.5, 0.5);
      final p1  = (1.0 + highlights * 0.1).clamp(0.5, 1.5);
      parts.add("curves=all='0/${p0.toStringAsFixed(3)} 0.5/0.5 1/${p1.toStringAsFixed(3)}'");
    }

    final vignette = (p['vignette'] as num?)?.toDouble() ?? 0.0;
    if (vignette > 0.001) {
      parts.add('vignette=angle=${(vignette * 1.5708).toStringAsFixed(4)}');
    }

    final grain = (p['film_grain'] as num?)?.toDouble() ?? 0.0;
    if (grain > 0.001) {
      parts.add('noise=alls=${(grain*30).toStringAsFixed(1)}:allf=t+u');
    }

    final sharpness = (p['sharpness'] as num?)?.toDouble() ?? 0.0;
    if (sharpness > 0.001) {
      parts.add('unsharp=5:5:${(sharpness*2).toStringAsFixed(2)}:5:5:0');
    } else if (sharpness < -0.001) {
      parts.add('gblur=sigma=${(sharpness.abs()*3).toStringAsFixed(2)}');
    }

    return parts.isEmpty ? 'null' : parts.join(',');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // مساعدات
  // ══════════════════════════════════════════════════════════════════════════
  Future<Directory> _createWorkDir() async {
    final tmp = await getTemporaryDirectory();
    final dir = Directory('${tmp.path}/export_${DateTime.now().millisecondsSinceEpoch}');
    await dir.create(recursive: true);
    return dir;
  }

  Future<String> _buildOutputPath(String name, String resolution) async {
    final ext  = await getExternalStorageDirectory();
    final dir  = Directory('${ext?.path ?? (await getTemporaryDirectory()).path}/CinematicEditor/exports');
    await dir.create(recursive: true);
    final safe = name.replaceAll(RegExp(r'[^\w\s.-]'), '_');
    return '${dir.path}/${safe}_${resolution}_${DateTime.now().millisecondsSinceEpoch}.mp4';
  }
}

class ExportException implements Exception {
  final String message;
  const ExportException(this.message);
  @override String toString() => 'ExportException: $message';
}
