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
      await _pumpInitialAppLoad();
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
      await _pumpInitialAppLoad();
    }
  }

  Future<void> _pumpInitialAppLoad() async {
    /*
     * Home starts several independent asynchronous sections at the same time.
     *
     * Some of those sections briefly render indeterminate progress indicators.
     * pumpAndSettle is therefore not appropriate for application bootstrap,
     * because indeterminate animations can keep scheduling frames.
     *
     * A few deterministic pumps are enough to:
     *
     * - mount the router;
     * - start the Home requests;
     * - allow mocked API futures to complete;
     * - rebuild the final loaded state.
     */
    await pump();
    await pump(const Duration(milliseconds: 100));
    await pump(const Duration(milliseconds: 100));
  }
}
