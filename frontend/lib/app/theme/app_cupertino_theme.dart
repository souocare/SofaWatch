import 'package:flutter/cupertino.dart';
import 'package:sofawatch/app/theme/tokens/app_colors.dart';
import 'package:sofawatch/app/theme/tokens/app_typography.dart';

abstract final class AppCupertinoTheme {
  static CupertinoThemeData get dark {
    return CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      primaryContrastingColor: AppColors.onPrimary,
      scaffoldBackgroundColor: AppColors.background,
      barBackgroundColor: AppColors.surface.withValues(alpha: 0.92),
      textTheme: CupertinoTextThemeData(
        primaryColor: AppColors.primary,
        textStyle: AppTypography.bodyMedium,
        actionTextStyle: AppTypography.labelLarge.copyWith(
          color: AppColors.primarySoft,
        ),
        tabLabelTextStyle: AppTypography.labelSmall,
        navTitleTextStyle: AppTypography.titleMedium,
        navLargeTitleTextStyle: AppTypography.headlineLargeMobile,
        pickerTextStyle: AppTypography.bodyLarge,
        dateTimePickerTextStyle: AppTypography.bodyLarge,
      ),
    );
  }
}
