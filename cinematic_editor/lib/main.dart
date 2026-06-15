// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import 'shared/theme/app_theme.dart';
import 'core/engine/native_engine_bridge.dart';
import 'features/export/services/ffmpeg_executor.dart';
import 'features/export/services/export_service.dart';
import 'features/subscription/services/device_security_service.dart';
import 'features/editor/presentation/screens/editor_screen.dart';

final GetIt sl = GetIt.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── اتجاه الشاشة ─────────────────────────────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── تهيئة FFmpegKit ───────────────────────────────────────────────────────
  await FFmpegExecutor.initialize();

  // ── تسجيل الخدمات ────────────────────────────────────────────────────────
  _setupServiceLocator();

  runApp(const CinematicEditorApp());
}

void _setupServiceLocator() {
  sl.registerLazySingleton<DeviceSecurityService>(() => DeviceSecurityService());
  sl.registerLazySingleton<NativeEngineBridge>(() => NativeEngineBridge());
  sl.registerLazySingleton<ExportService>(
    () => ExportService(deviceSecurity: sl<DeviceSecurityService>()),
  );
}

class CinematicEditorApp extends StatelessWidget {
  const CinematicEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:                   'Cinematic Editor',
      debugShowCheckedModeBanner: false,
      theme:                   AppTheme.darkTheme,
      themeMode:               ThemeMode.dark,
      home:                    const EditorScreen(projectId: 'default_project'),
    );
  }
}
