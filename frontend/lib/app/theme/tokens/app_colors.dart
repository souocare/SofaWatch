import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand

  static const Color primary = Color(0xFFE24E42);

  static const Color primarySoft = Color(0xFFFFB4AA);

  static const Color primaryContainer = Color(0xFFF75D4F);

  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color onPrimaryDark = Color(0xFF690004);

  // Background and surfaces

  static const Color background = Color(0xFF0A0A0A);

  static const Color surface = Color(0xFF131313);

  static const Color surfaceLowest = Color(0xFF0E0E0E);

  static const Color surfaceLow = Color(0xFF1C1B1B);

  static const Color surfaceContainer = Color(0xFF201F1F);

  static const Color surfaceHigh = Color(0xFF2A2A2A);

  static const Color surfaceHighest = Color(0xFF353534);

  static const Color surfaceBright = Color(0xFF3A3939);

  // Text and content

  static const Color onBackground = Color(0xFFE5E2E1);

  static const Color onSurface = Color(0xFFE5E2E1);

  static const Color onSurfaceVariant = Color(0xFFE1BFBA);

  static const Color textPrimary = onSurface;

  static const Color textSecondary = Color(0xFFC8C6C5);

  static const Color textMuted = Color(0xFF929090);

  static const Color textDisabled = Color(0xFF686666);

  // Secondary and tertiary

  static const Color secondary = Color(0xFFC8C6C5);

  static const Color onSecondary = Color(0xFF313030);

  static const Color secondaryContainer = Color(0xFF474746);

  static const Color tertiary = Color(0xFFC8C6C6);

  static const Color onTertiary = Color(0xFF303030);

  // Borders and dividers

  static const Color outline = Color(0xFFA98985);

  static const Color outlineVariant = Color(0xFF59413E);

  static const Color border = Color(0xFF333333);

  static const Color divider = Color(0xFF2A2A2A);

  // Status colors

  static const Color error = Color(0xFFFFB4AB);

  static const Color onError = Color(0xFF690005);

  static const Color errorContainer = Color(0xFF93000A);

  static const Color onErrorContainer = Color(0xFFFFDAD6);

  static const Color success = Color(0xFF75C995);

  static const Color warning = Color(0xFFE4B65A);

  static const Color information = Color(0xFF82B8E8);

  // Media and progress

  static const Color progressTrack = Color(0xFF353534);

  static const Color progressValue = primary;

  static const Color rating = primarySoft;

  // Glass and overlays

  static const Color glassSurface = Color(0x1AFFFFFF);

  static const Color glassBorder = Color(0x26FFFFFF);

  static const Color modalBarrier = Color(0x99000000);

  static const Color scrim = Color(0xB3000000);

  // Inverse colors

  static const Color inverseSurface = Color(0xFFE5E2E1);

  static const Color inverseOnSurface = Color(0xFF313030);

  static const Color inversePrimary = Color(0xFFB12B24);

  static const Color surfaceSubtle = Color(0xFF1B1B1B);
}
