@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';
import 'test_bootstrap_data.dart';

void main() {
  testWidgets('mounts the configured application on Home', (
    WidgetTester tester,
  ) async {
    await tester.pumpSofaWatchApp();

    expect(find.byKey(const ValueKey<String>('home-page')), findsOneWidget);

    expect(
      find.byKey(const ValueKey<String>('mobile-bottom-navigation')),
      findsOneWidget,
    );
  });

  testWidgets('mounts the application without a configured server', (
    WidgetTester tester,
  ) async {
    await tester.pumpSofaWatchApp(
      bootstrapData: createTestBootstrapData(hasConfiguredServer: false),
    );

    expect(
      find.byKey(const ValueKey<String>('server-setup-page-title')),
      findsOneWidget,
    );
  });
}
