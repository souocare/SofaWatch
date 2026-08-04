import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sofawatch/app/theme/tokens/app_colors.dart';

@immutable
class SofaWatchThemeExtension extends ThemeExtension<SofaWatchThemeExtension> {
  const SofaWatchThemeExtension({
    required this.background,
    required this.cardSurface,
    required this.cardSurfaceHover,
    required this.glassSurface,
    required this.glassBorder,
    required this.progressTrack,
    required this.progressValue,
    required this.rating,
    required this.modalBarrier,
    required this.glassBlur,
  });

  const SofaWatchThemeExtension.dark()
    : background = AppColors.background,
      cardSurface = AppColors.surfaceLow,
      cardSurfaceHover = AppColors.surfaceHigh,
      glassSurface = AppColors.glassSurface,
      glassBorder = AppColors.glassBorder,
      progressTrack = AppColors.progressTrack,
      progressValue = AppColors.progressValue,
      rating = AppColors.rating,
      modalBarrier = AppColors.modalBarrier,
      glassBlur = 20;

  final Color background;
  final Color cardSurface;
  final Color cardSurfaceHover;

  final Color glassSurface;
  final Color glassBorder;
  final double glassBlur;

  final Color progressTrack;
  final Color progressValue;
  final Color rating;

  final Color modalBarrier;

  @override
  SofaWatchThemeExtension copyWith({
    Color? background,
    Color? cardSurface,
    Color? cardSurfaceHover,
    Color? glassSurface,
    Color? glassBorder,
    double? glassBlur,
    Color? progressTrack,
    Color? progressValue,
    Color? rating,
    Color? modalBarrier,
  }) {
    return SofaWatchThemeExtension(
      background: background ?? this.background,
      cardSurface: cardSurface ?? this.cardSurface,
      cardSurfaceHover: cardSurfaceHover ?? this.cardSurfaceHover,
      glassSurface: glassSurface ?? this.glassSurface,
      glassBorder: glassBorder ?? this.glassBorder,
      glassBlur: glassBlur ?? this.glassBlur,
      progressTrack: progressTrack ?? this.progressTrack,
      progressValue: progressValue ?? this.progressValue,
      rating: rating ?? this.rating,
      modalBarrier: modalBarrier ?? this.modalBarrier,
    );
  }

  @override
  SofaWatchThemeExtension lerp(
    covariant SofaWatchThemeExtension? other,
    double t,
  ) {
    if (other == null) {
      return this;
    }

    return SofaWatchThemeExtension(
      background: Color.lerp(background, other.background, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      cardSurfaceHover: Color.lerp(
        cardSurfaceHover,
        other.cardSurfaceHover,
        t,
      )!,
      glassSurface: Color.lerp(glassSurface, other.glassSurface, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassBlur: lerpDouble(glassBlur, other.glassBlur, t)!,
      progressTrack: Color.lerp(progressTrack, other.progressTrack, t)!,
      progressValue: Color.lerp(progressValue, other.progressValue, t)!,
      rating: Color.lerp(rating, other.rating, t)!,
      modalBarrier: Color.lerp(modalBarrier, other.modalBarrier, t)!,
    );
  }
}

extension SofaWatchThemeContext on BuildContext {
  SofaWatchThemeExtension get sofaWatchTheme {
    final SofaWatchThemeExtension? extension = Theme.of(
      this,
    ).extension<SofaWatchThemeExtension>();

    assert(
      extension != null,
      'SofaWatchThemeExtension is not registered in ThemeData.',
    );

    return extension!;
  }
}
