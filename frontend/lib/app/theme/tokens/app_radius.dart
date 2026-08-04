import 'package:flutter/widgets.dart';

abstract final class AppRadius {
  static const double noneValue = 0;
  static const double smallValue = 4;
  static const double mediumValue = 8;
  static const double largeValue = 12;
  static const double extraLargeValue = 16;
  static const double modalValue = 24;
  static const double fullValue = 9999;

  static const Radius none = Radius.circular(noneValue);

  static const Radius small = Radius.circular(smallValue);

  static const Radius medium = Radius.circular(mediumValue);

  static const Radius large = Radius.circular(largeValue);

  static const Radius extraLarge = Radius.circular(extraLargeValue);

  static const Radius modal = Radius.circular(modalValue);

  static const Radius full = Radius.circular(fullValue);

  static const BorderRadius borderNone = BorderRadius.all(none);

  static const BorderRadius borderSmall = BorderRadius.all(small);

  static const BorderRadius borderMedium = BorderRadius.all(medium);

  static const BorderRadius borderLarge = BorderRadius.all(large);

  static const BorderRadius borderExtraLarge = BorderRadius.all(extraLarge);

  static const BorderRadius borderModal = BorderRadius.all(modal);

  static const BorderRadius borderFull = BorderRadius.all(full);

  static const BorderRadius card = borderLarge;
  static const BorderRadius input = borderMedium;
  static const BorderRadius button = borderMedium;
  static const BorderRadius navigation = borderFull;
  static const BorderRadius dialog = borderExtraLarge;
  static const BorderRadius detailsModal = borderModal;
}
