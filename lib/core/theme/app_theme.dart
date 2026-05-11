import 'package:flutter/material.dart';

/// KineCue 品牌颜色。
abstract final class AppColors {
  // ── 品牌色 ─────────────────────────────────────────────
  static const Color primary = Color(0xFF2076F5);
  static const Color primaryLight = Color(0xFF64A0FF);
  static const Color primaryDark = Color(0xFF1558B8);

  // ── 表面 ───────────────────────────────────────────────
  static const Color surface = Color(0xFF121212);
  static final Color surfaceVariant = Colors.white.withValues(alpha: 0.06);
  static final Color surfaceBright = Colors.white.withValues(alpha: 0.10);

  // ── 文字 / 图标 ────────────────────────────────────────
  static const Color onSurface = Colors.white;
  static final Color onSurfaceHigh = Colors.white.withValues(alpha: 0.87);
  static final Color onSurfaceMedium = Colors.white.withValues(alpha: 0.60);
  static final Color onSurfaceLow = Colors.white.withValues(alpha: 0.38);
  static final Color onSurfaceDisabled = Colors.white.withValues(alpha: 0.20);

  // ── 语义色 ─────────────────────────────────────────────
  static const Color error = Colors.redAccent;
  static const Color warning = Colors.amberAccent;
  static const Color caution = Colors.orangeAccent;

  // ── 覆盖层 ─────────────────────────────────────────────
  static final Color overlay = Colors.black.withValues(alpha: 0.85);
  static final Color overlayDark = Colors.black.withValues(alpha: 0.90);
  static final Color overlayLight = Colors.black.withValues(alpha: 0.55);
  static final Color overlaySubtle = Colors.black.withValues(alpha: 0.38);

  // ── 分隔 / 边框 ────────────────────────────────────────
  static final Color divider = Colors.white.withValues(alpha: 0.10);
  static final Color cardBorder = Colors.white.withValues(alpha: 0.15);

  // ── 卡片 / 容器 ────────────────────────────────────────
  static final Color card = Colors.white.withValues(alpha: 0.08);
  static final Color cardSubtle = Colors.white.withValues(alpha: 0.05);

  // ── 按钮 ───────────────────────────────────────────────
  static final Color buttonEnabled = Colors.white.withValues(alpha: 0.12);
  static final Color buttonDisabled = Colors.white.withValues(alpha: 0.04);
  static final Color buttonIconEnabled = Colors.white.withValues(alpha: 0.70);
  static final Color buttonIconDisabled = Colors.white.withValues(alpha: 0.20);
}

/// 间距与圆角常量。
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double pagePadding = 24;
  static const double cardRadius = 12;
  static const double cardRadiusLg = 16;
  static const double buttonRadius = 12;
  static const double bubbleRadius = 20;
}

/// KineCue 暗色主题。
abstract final class AppTheme {
  static ThemeData get darkTheme => ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.surface,
        colorScheme: ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.primaryLight,
          surface: AppColors.surface,
          error: AppColors.error,
          onPrimary: Colors.black,
          onSurface: AppColors.onSurface,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.onSurfaceHigh,
            side: BorderSide(color: AppColors.onSurfaceDisabled),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.onSurface,
          elevation: 0,
        ),
      );
}
