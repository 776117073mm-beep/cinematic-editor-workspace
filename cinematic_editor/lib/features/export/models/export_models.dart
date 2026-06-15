// lib/features/export/models/export_models.dart
import 'package:equatable/equatable.dart';

class ExportSettings {
  final String resolution;
  final double frameRate;
  final ExportQuality quality;
  final int videoBitrateKbps;
  final int audioBitrateKbps;
  final bool hasSubscription;
  final bool useHardwareAccel;

  const ExportSettings({
    required this.resolution,
    required this.frameRate,
    required this.quality,
    required this.videoBitrateKbps,
    required this.audioBitrateKbps,
    required this.hasSubscription,
    this.useHardwareAccel = true,
  });

  factory ExportSettings.hd({required bool hasSubscription}) => ExportSettings(
    resolution: '1080p', frameRate: 30.0, quality: ExportQuality.high,
    videoBitrateKbps: 8000, audioBitrateKbps: 192, hasSubscription: hasSubscription,
  );

  factory ExportSettings.ultraHD({required bool hasSubscription}) => ExportSettings(
    resolution: '4K', frameRate: 24.0, quality: ExportQuality.ultraHigh,
    videoBitrateKbps: 40000, audioBitrateKbps: 320, hasSubscription: hasSubscription,
  );
}

enum ExportQuality { low, medium, high, ultraHigh }

class ExportProgress extends Equatable {
  final ExportStage stage;
  final double progress;
  final int? currentClipIndex;
  final int? totalClips;
  final String? currentClipName;
  final int? elapsedSeconds;
  final bool isCompleted;
  final bool isFailed;
  final String? outputPath;
  final int? fileSizeBytes;
  final int? totalSeconds;
  final String? resolution;
  final String? errorMessage;

  const ExportProgress({
    required this.stage,
    required this.progress,
    this.currentClipIndex, this.totalClips, this.currentClipName,
    this.elapsedSeconds,
    this.isCompleted = false, this.isFailed = false,
    this.outputPath, this.fileSizeBytes, this.totalSeconds,
    this.resolution, this.errorMessage,
  });

  factory ExportProgress.stage({required ExportStage stage, required double progress}) =>
      ExportProgress(stage: stage, progress: progress);

  factory ExportProgress.completed({
    required String outputPath, required int fileSizeBytes,
    required int totalSeconds, required String resolution,
  }) => ExportProgress(
    stage: ExportStage.completed, progress: 1.0, isCompleted: true,
    outputPath: outputPath, fileSizeBytes: fileSizeBytes,
    totalSeconds: totalSeconds, resolution: resolution,
  );

  factory ExportProgress.failed({required String error}) => ExportProgress(
    stage: ExportStage.failed, progress: 0.0, isFailed: true, errorMessage: error,
  );

  String get stageDescription => switch (stage) {
    ExportStage.validating     => 'التحقق من الصلاحيات...',
    ExportStage.preparing      => 'تحضير بيئة التصدير...',
    ExportStage.processingClips =>
      currentClipIndex != null ? 'معالجة مقطع ${currentClipIndex! + 1} من $totalClips'
                               : 'معالجة المقاطع...',
    ExportStage.concatenating  => 'دمج المقاطع...',
    ExportStage.mixingAudio    => 'مزج مسارات الصوت...',
    ExportStage.addingText     => 'إضافة النصوص...',
    ExportStage.encoding       => 'تشفير الفيديو النهائي...',
    ExportStage.finalizing     => 'إنهاء العملية...',
    ExportStage.completed      => 'اكتمل التصدير بنجاح!',
    ExportStage.failed         => 'فشل التصدير',
  };

  String? get estimatedTimeRemaining {
    if (elapsedSeconds == null || progress <= 0.01 || isCompleted || isFailed) return null;
    final rem = ((elapsedSeconds! / progress) - elapsedSeconds!).round();
    if (rem < 60) return '$rem ثانية';
    return '${(rem / 60).round()} دقيقة';
  }

  @override List<Object?> get props => [stage, progress, isCompleted, isFailed];
}

enum ExportStage {
  validating, preparing, processingClips, concatenating,
  mixingAudio, addingText, encoding, finalizing, completed, failed,
}
