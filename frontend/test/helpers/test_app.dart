import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/app/app.dart';
import 'package:sofawatch/app/app_bootstrap_data.dart';

import 'test_bootstrap_data.dart';

extension SofaWatchWidgetTesterExtension on WidgetTester {
  Future<void> pumpSofaWatchApp({
    AppBootstrapData? bootstrapData,
    Size surfaceSize = const Size(390, 844),
    bool settle = true,
  }) async {
    await binding.setSurfaceSize(surfaceSize);

    addTearDown(() async {
      await binding.setSurfaceSize(null);
    });

    await pumpWidget(
      SofaWatchApp(bootstrapData: bootstrapData ?? createTestBootstrapData()),
    );

    if (settle) {
      await pumpAndSettle();
    }
  }

  Future<void> pumpSofaWatchWebApp({
    AppBootstrapData? bootstrapData,
    Size surfaceSize = const Size(1440, 900),
    bool settle = true,
  }) async {
    await binding.setSurfaceSize(surfaceSize);

    addTearDown(() async {
      await binding.setSurfaceSize(null);
    });

    await pumpWidget(
      SofaWatchApp(bootstrapData: bootstrapData ?? createTestBootstrapData()),
    );

    if (settle) {
      await pumpAndSettle();
    }
  }
}
