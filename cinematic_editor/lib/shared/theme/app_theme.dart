// lib/shared/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary:   AppColors.accentPrimary,
        secondary: AppColors.accentSecondary,
        tertiary:  AppColors.accentAI,
        surface:   AppColors.backgroundSecondary,
        error:     AppColors.accentDanger,
        onPrimary: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.backgroundPrimary,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundSecondary,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge:  TextStyle(color: AppColors.textPrimary,   fontSize: 32, fontWeight: FontWeight.w700),
        headlineLarge: TextStyle(color: AppColors.textPrimary,   fontSize: 24, fontWeight: FontWeight.w600),
        headlineMedium:TextStyle(color: AppColors.textPrimary,   fontSize: 20, fontWeight: FontWeight.w500),
        titleLarge:    TextStyle(color: AppColors.textPrimary,   fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium:   TextStyle(color: AppColors.textPrimary,   fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge:     TextStyle(color: AppColors.textPrimary,   fontSize: 16),
        bodyMedium:    TextStyle(color: AppColors.textSecondary, fontSize: 14),
        bodySmall:     TextStyle(color: AppColors.textTertiary,  fontSize: 12),
        labelLarge:    TextStyle(color: AppColors.textPrimary,   fontSize: 14, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentPrimary,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.backgroundElevated,
        thickness: 1,
      ),
    );
  }
}
