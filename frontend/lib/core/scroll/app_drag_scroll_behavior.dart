import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class AppDragScrollBehavior extends MaterialScrollBehavior {
  const AppDragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const <PointerDeviceKind>{
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}
