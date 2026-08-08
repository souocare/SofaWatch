import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/explore/presentation/pages/explore_page.dart';

void main() {
  group('ExplorePage', () {
    testWidgets('shows the Explore discovery header', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ExplorePage())),
      );

      expect(
        find.byKey(const ValueKey<String>('explore-page-title')),
        findsOneWidget,
      );

      expect(find.text('Explore'), findsOneWidget);

      expect(find.text('Discover something worth watching.'), findsOneWidget);
    });

    testWidgets('provides a scrollable content area for discovery sections', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ExplorePage())),
      );

      expect(
        find.byKey(const ValueKey<String>('explore-scroll-view')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('explore-content')),
        findsOneWidget,
      );
    });

    testWidgets('does not expose a local Search field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ExplorePage())),
      );

      expect(find.byType(TextField), findsNothing);
    });
  });
}
