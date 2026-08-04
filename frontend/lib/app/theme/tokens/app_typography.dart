import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sofawatch/app/theme/tokens/app_colors.dart';

abstract final class AppTypography {
  static TextStyle get headlineExtraLarge {
    return GoogleFonts.manrope(
      fontSize: 48,
      height: 56 / 48,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.96,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle get headlineLarge {
    return GoogleFonts.manrope(
      fontSize: 32,
      height: 40 / 32,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.32,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle get headlineLargeMobile {
    return GoogleFonts.manrope(
      fontSize: 28,
      height: 36 / 28,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.28,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle get headlineMedium {
    return GoogleFonts.manrope(
      fontSize: 24,
      height: 32 / 24,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.24,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle get headlineSmall {
    return GoogleFonts.manrope(
      fontSize: 20,
      height: 28 / 20,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle get titleLarge {
    return GoogleFonts.manrope(
      fontSize: 20,
      height: 28 / 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle get titleMedium {
    return GoogleFonts.manrope(
      fontSize: 18,
      height: 26 / 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle get titleSmall {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle get bodyLarge {
    return GoogleFonts.manrope(
      fontSize: 18,
      height: 28 / 18,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle get bodyMedium {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle get bodySmall {
    return GoogleFonts.manrope(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
    );
  }

  static TextStyle get labelLarge {
    return GoogleFonts.manrope(
      fontSize: 16,
      height: 22 / 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle get labelMedium {
    return GoogleFonts.manrope(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.7,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle get labelSmall {
    return GoogleFonts.manrope(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.6,
      color: AppColors.textSecondary,
    );
  }

  static TextStyle get overline {
    return GoogleFonts.manrope(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
      color: AppColors.primarySoft,
    );
  }
}
