import 'package:flutter/animation.dart';

abstract final class AppDurations {
  static const Duration instant = Duration.zero;

  static const Duration veryFast = Duration(milliseconds: 100);

  static const Duration fast = Duration(milliseconds: 150);

  static const Duration normal = Duration(milliseconds: 250);

  static const Duration slow = Duration(milliseconds: 350);

  static const Duration verySlow = Duration(milliseconds: 500);

  static const Duration debounce = Duration(milliseconds: 350);

  static const Duration toast = Duration(seconds: 3);

  static const Duration modalEnter = normal;
  static const Duration modalExit = fast;
  static const Duration hover = veryFast;
  static const Duration button = fast;
  static const Duration pageTransition = normal;

  static const Curve standardCurve = Curves.easeInOutCubic;
  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;
  static const Curve emphasizedCurve = Curves.easeOutBack;
}
