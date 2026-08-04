import 'package:flutter/widgets.dart';

abstract final class AppSpacing {
  static const double none = 0;

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double extraHuge = 48;
  static const double section = 64;
  static const double sectionLarge = 80;

  static const double mobileHorizontalPadding = 20;
  static const double desktopHorizontalPadding = 64;

  static const double mobileGutter = 16;
  static const double desktopGutter = 24;

  static const double maxContentWidth = 1440;

  static const EdgeInsets mobilePagePadding = EdgeInsets.symmetric(
    horizontal: mobileHorizontalPadding,
  );

  static const EdgeInsets desktopPagePadding = EdgeInsets.symmetric(
    horizontal: desktopHorizontalPadding,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(lg);

  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(xxl);

  static const EdgeInsets modalPadding = EdgeInsets.all(xxl);

  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );
}
