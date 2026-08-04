import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';

import 'helpers/test_app.dart';

void main() {
  testWidgets('redirects the initial route to Home', (
    WidgetTester tester,
  ) async {
    await tester.pumpSofaWatchApp();

    expect(
      find.byKey(const ValueKey<String>('home-page-title')),
      findsOneWidget,
    );

    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('switches between the main tabs', (WidgetTester tester) async {
    await tester.pumpSofaWatchApp();

    await tester.tap(find.text('Shows').last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('shows-page-title')),
      findsOneWidget,
    );

    await tester.tap(find.text('Movies').last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('movies-page-title')),
      findsOneWidget,
    );

    await tester.tap(find.text('Explore').last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('explore-page-title')),
      findsOneWidget,
    );

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('profile-page-title')),
      findsOneWidget,
    );
  });

  testWidgets('returns to the previously selected branch', (
    WidgetTester tester,
  ) async {
    await tester.pumpSofaWatchApp();

    await tester.tap(find.text('Shows').last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('shows-page-title')),
      findsOneWidget,
    );

    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('home-page-title')),
      findsOneWidget,
    );

    await tester.tap(find.text('Shows').last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('shows-page-title')),
      findsOneWidget,
    );
  });

  testWidgets('shows bottom navigation on mobile platforms', (
    WidgetTester tester,
  ) async {
    await tester.pumpSofaWatchApp();

    expect(
      find.byKey(const ValueKey<String>('mobile-bottom-navigation')),
      findsOneWidget,
    );

    expect(
      find.byKey(const ValueKey<String>('web-top-navigation')),
      findsNothing,
    );
  });

  testWidgets('opens and closes show details', (WidgetTester tester) async {
    await tester.pumpSofaWatchApp();

    final BuildContext context = tester.element(
      find.byKey(const ValueKey<String>('home-page-title')),
    );

    context.pushNamed(
      AppRoute.showDetails.name,
      pathParameters: <String, String>{'showId': 'show-123'},
    );

    await tester.pumpAndSettle();

    expect(find.text('Show Details'), findsWidgets);

    expect(find.text('show-123'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));

    await tester.pumpAndSettle();

    expect(find.text('show-123'), findsNothing);
  });

  testWidgets('opens episode details', (WidgetTester tester) async {
    await tester.pumpSofaWatchApp();

    final BuildContext context = tester.element(
      find.byKey(const ValueKey<String>('home-page-title')),
    );

    context.pushNamed(
      AppRoute.episodeDetails.name,
      pathParameters: <String, String>{'episodeId': 'episode-456'},
    );

    await tester.pumpAndSettle();

    expect(find.text('Episode Details'), findsWidgets);

    expect(find.text('episode-456'), findsOneWidget);
  });
}
