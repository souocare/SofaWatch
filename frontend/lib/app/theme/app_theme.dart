import 'package:flutter/material.dart';
import 'package:sofawatch/app/theme/app_material_theme.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    return AppMaterialTheme.dark;
  }
}
