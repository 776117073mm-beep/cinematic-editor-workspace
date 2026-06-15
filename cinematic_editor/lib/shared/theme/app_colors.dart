// lib/shared/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── خلفيات ──────────────────────────────────────────────────────────────
  static const Color backgroundPrimary    = Color(0xFF0A0A0F);
  static const Color backgroundSecondary  = Color(0xFF12121A);
  static const Color backgroundTertiary   = Color(0xFF1A1A26);
  static const Color backgroundElevated   = Color(0xFF22222F);

  // ── التايم لاين ──────────────────────────────────────────────────────────
  static const Color timelineBackground   = Color(0xFF0D0D15);
  static const Color timelineTrackVideo   = Color(0xFF1E3A5F);
  static const Color timelineTrackAudio   = Color(0xFF1F4A2E);
  static const Color timelineTrackText    = Color(0xFF4A2E1F);
  static const Color timelinePlayhead     = Color(0xFFFF3B3B);
  static const Color timelineClipBorder   = Color(0xFF3D3D5C);

  // ── ألوان تمييزية ─────────────────────────────────────────────────────────
  static const Color accentPrimary        = Color(0xFF6C63FF);
  static const Color accentSecondary      = Color(0xFF00D4FF);
  static const Color accentAI             = Color(0xFF9D4EDD);
  static const Color accentSuccess        = Color(0xFF00E676);
  static const Color accentWarning        = Color(0xFFFFAB00);
  static const Color accentDanger         = Color(0xFFFF3D00);

  // ── نصوص ────────────────────────────────────────────────────────────────
  static const Color textPrimary          = Color(0xFFF5F5FF);
  static const Color textSecondary        = Color(0xFFB0B0CC);
  static const Color textTertiary         = Color(0xFF6B6B8A);
  static const Color textDisabled         = Color(0xFF3D3D5C);

  // ── تدرجات ──────────────────────────────────────────────────────────────
  static const LinearGradient aiButtonGradient = LinearGradient(
    colors: [Color(0xFF9D4EDD), Color(0xFF6C63FF), Color(0xFF00D4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient toolbarGradient = LinearGradient(
    colors: [Color(0xFF0A0A0F), Color(0xFF12121A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient previewOverlayGradient = LinearGradient(
    colors: [Colors.transparent, Color(0x990A0A0F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── توهجات ──────────────────────────────────────────────────────────────
  static List<BoxShadow> aiButtonGlow = [
    BoxShadow(color: Color(0xFF9D4EDD), blurRadius: 20, spreadRadius: 2),
    BoxShadow(color: Color(0xFF6C63FF), blurRadius: 40, spreadRadius: 5),
  ];
  static List<BoxShadow> accentGlow = [
    BoxShadow(color: accentPrimary, blurRadius: 15, spreadRadius: 1),
  ];
}
