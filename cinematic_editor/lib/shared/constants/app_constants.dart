// lib/shared/constants/app_constants.dart
class AppConstants {
  AppConstants._();

  // ══════════════════════════════════════════════
  // [PLACEHOLDER] مفاتيح API - يجب تعبئتها قبل الإنتاج
  // ══════════════════════════════════════════════
  static const String apiBaseUrl        = 'https://api.cinematiceditor.com/v1';
  static const String wsBaseUrl         = 'wss://ws.cinematiceditor.com/v1';
  // RevenueCat keys  → lib/features/subscription/services/subscription_service.dart
  // Firebase config  → flutterfire configure
  // Anthropic key    → backend/.env
  // AWS credentials  → backend/.env

  // ══════════════════════════════════════════════
  // حدود الفترة التجريبية
  // ══════════════════════════════════════════════
  static const int    freeTrialDays          = 3;
  static const int    freeExportLimit4K      = 3;
  static const int    freeExportLimit1080p   = 10;

  // ══════════════════════════════════════════════
  // إعدادات التايم لاين
  // ══════════════════════════════════════════════
  static const double defaultTimelineZoom    = 1.0;
  static const double minTimelineZoom        = 0.1;
  static const double maxTimelineZoom        = 10.0;
  static const double trackHeight            = 60.0;
  static const double audioTrackHeight       = 48.0;
  static const double timelineHeaderHeight   = 30.0;
  static const double pixelsPerSecond        = 50.0;

  // ══════════════════════════════════════════════
  // إعدادات Proxy
  // ══════════════════════════════════════════════
  static const String proxyResolution        = '360p';
  static const int    proxyBitrate           = 800;
  static const int    proxyCRF               = 28;

  // ══════════════════════════════════════════════
  // Undo/Redo
  // ══════════════════════════════════════════════
  static const int maxUndoSteps              = 100;

  // ══════════════════════════════════════════════
  // مفاتيح التخزين المحلي
  // ══════════════════════════════════════════════
  static const String deviceIdKey            = 'device_unique_id';
  static const String userTokenKey           = 'user_auth_token';
  static const String subscriptionKey        = 'subscription_status';
  static const String trialStartKey          = 'trial_start_timestamp';
  static const String exportCountKey         = 'export_count_';

  // ══════════════════════════════════════════════
  // مسارات الملفات
  // ══════════════════════════════════════════════
  static const String projectsFolder         = 'projects';
  static const String proxiesFolder          = 'proxies';
  static const String thumbnailsFolder       = 'thumbnails';
  static const String exportsFolder          = 'exports';
  static const String tempFolder             = 'temp';
}
