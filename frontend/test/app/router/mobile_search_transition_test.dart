import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/search/presentation/views/search_mobile_view.dart';
import 'package:sofawatch/features/search/presentation/widgets/search_text_field.dart';

import '../../helpers/test_app.dart';

void main() {
  const ValueKey<String> searchActionKey = ValueKey<String>(
    'mobile-search-pill-action',
  );

  const ValueKey<String> closeSearchActionKey = ValueKey<String>(
    'mobile-search-close-action',
  );

  const ValueKey<String> primaryNavigationPillKey = ValueKey<String>(
    'mobile-primary-navigation-pill',
  );

  const ValueKey<String> compactNavigationPillKey = ValueKey<String>(
    'mobile-compact-navigation-pill',
  );

  const ValueKey<String> compactSearchPillKey = ValueKey<String>(
    'mobile-search-pill',
  );

  const ValueKey<String> expandedSearchPillKey = ValueKey<String>(
    'mobile-search-expanded-pill',
  );

  const ValueKey<String> showsNavigationKey = ValueKey<String>(
    'mobile-navigation-shows',
  );

  const ValueKey<String> homePageTitleKey = ValueKey<String>('home-page-title');

  const ValueKey<String> showsPageTitleKey = ValueKey<String>(
    'shows-page-title',
  );

  double widthOf(WidgetTester tester, Finder finder) {
    return tester.getSize(finder).width;
  }

  group('Mobile Search transition', () {
    testWidgets('opens Search after completing the pill transition', (
      WidgetTester tester,
    ) async {
      await tester.pumpSofaWatchApp();

      expect(find.byKey(homePageTitleKey), findsOneWidget);
      expect(find.byType(SearchMobileView), findsNothing);
      expect(find.byKey(compactSearchPillKey), findsOneWidget);
      expect(find.byKey(expandedSearchPillKey), findsNothing);

      await tester.tap(find.byKey(searchActionKey));

      // Inicia a transição.
      await tester.pump();

      expect(find.byType(SearchMobileView), findsOneWidget);
      expect(find.byKey(expandedSearchPillKey), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.byType(SearchTextField), findsOneWidget);
      expect(find.byKey(compactNavigationPillKey), findsOneWidget);
      expect(find.byKey(closeSearchActionKey), findsOneWidget);
    });

    testWidgets('animates the primary and Search pill widths', (
      WidgetTester tester,
    ) async {
      await tester.pumpSofaWatchApp();

      final double initialNavigationWidth = widthOf(
        tester,
        find.byKey(primaryNavigationPillKey),
      );

      final double initialSearchWidth = widthOf(
        tester,
        find.byKey(compactSearchPillKey),
      );

      expect(initialNavigationWidth, greaterThan(initialSearchWidth));

      await tester.tap(find.byKey(searchActionKey));
      await tester.pump();

      // Aproximadamente a meio da animação de 320 ms.
      await tester.pump(const Duration(milliseconds: 160));

      final double intermediateNavigationWidth = widthOf(
        tester,
        find.byKey(primaryNavigationPillKey),
      );

      final double intermediateSearchWidth = widthOf(
        tester,
        find.byKey(expandedSearchPillKey),
      );

      expect(intermediateNavigationWidth, lessThan(initialNavigationWidth));

      expect(intermediateNavigationWidth, greaterThan(initialSearchWidth));

      expect(intermediateSearchWidth, greaterThan(initialSearchWidth));

      expect(intermediateSearchWidth, lessThan(initialNavigationWidth));

      await tester.pumpAndSettle();

      final double finalCompactNavigationWidth = widthOf(
        tester,
        find.byKey(compactNavigationPillKey),
      );

      final double finalSearchWidth = widthOf(
        tester,
        find.byKey(expandedSearchPillKey),
      );

      expect(finalCompactNavigationWidth, lessThan(finalSearchWidth));
    });

    testWidgets('closes Search with the compact return pill', (
      WidgetTester tester,
    ) async {
      await tester.pumpSofaWatchApp();

      await tester.tap(find.byKey(searchActionKey));
      await tester.pumpAndSettle();

      expect(find.byType(SearchMobileView), findsOneWidget);
      expect(find.byType(SearchTextField), findsOneWidget);

      await tester.tap(find.byKey(closeSearchActionKey));
      await tester.pumpAndSettle();

      expect(find.byType(SearchMobileView), findsNothing);
      expect(find.byType(SearchTextField), findsNothing);
      expect(find.byKey(primaryNavigationPillKey), findsOneWidget);
      expect(find.byKey(compactSearchPillKey), findsOneWidget);
      expect(find.byKey(homePageTitleKey), findsOneWidget);
    });

    testWidgets('closes Search when the system Back action is requested', (
      WidgetTester tester,
    ) async {
      await tester.pumpSofaWatchApp();

      await tester.tap(find.byKey(searchActionKey));
      await tester.pumpAndSettle();

      expect(find.byType(SearchMobileView), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(SearchMobileView), findsNothing);
      expect(find.byKey(primaryNavigationPillKey), findsOneWidget);
      expect(find.byKey(homePageTitleKey), findsOneWidget);
    });

    testWidgets('restores the branch from which Search was opened', (
      WidgetTester tester,
    ) async {
      await tester.pumpSofaWatchApp();

      await tester.tap(find.byKey(showsNavigationKey));
      await tester.pumpAndSettle();

      expect(find.byKey(showsPageTitleKey), findsOneWidget);

      await tester.tap(find.byKey(searchActionKey));
      await tester.pumpAndSettle();

      expect(find.byType(SearchMobileView), findsOneWidget);

      await tester.tap(find.byKey(closeSearchActionKey));
      await tester.pumpAndSettle();

      expect(find.byType(SearchMobileView), findsNothing);
      expect(find.byKey(showsPageTitleKey), findsOneWidget);
    });

    testWidgets('starts a new clean Search experience after reopening', (
      WidgetTester tester,
    ) async {
      await tester.pumpSofaWatchApp();

      await tester.tap(find.byKey(searchActionKey));
      await tester.pumpAndSettle();

      final Finder searchField = find.descendant(
        of: find.byType(SearchTextField),
        matching: find.byType(EditableText),
      );

      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'Breaking Bad');
      await tester.pump();

      expect(find.text('Breaking Bad'), findsOneWidget);

      await tester.tap(find.byKey(closeSearchActionKey));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(searchActionKey));
      await tester.pumpAndSettle();

      final EditableText reopenedField = tester.widget<EditableText>(
        find.descendant(
          of: find.byType(SearchTextField),
          matching: find.byType(EditableText),
        ),
      );

      expect(reopenedField.controller.text, isEmpty);
    });
  });

  testWidgets('uses an immediate transition when animations are disabled', (
    WidgetTester tester,
  ) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);

    addTearDown(() {
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue();
    });

    await tester.pumpSofaWatchApp();

    expect(find.byKey(compactSearchPillKey), findsOneWidget);

    await tester.tap(find.byKey(searchActionKey));

    // Um único frame deve aplicar diretamente o estado final.
    await tester.pump();

    expect(find.byType(SearchMobileView), findsOneWidget);
    expect(find.byKey(compactNavigationPillKey), findsOneWidget);
    expect(find.byKey(expandedSearchPillKey), findsOneWidget);

    await tester.tap(find.byKey(closeSearchActionKey));
    await tester.pump();

    expect(find.byType(SearchMobileView), findsNothing);
    expect(find.byKey(primaryNavigationPillKey), findsOneWidget);
    expect(find.byKey(compactSearchPillKey), findsOneWidget);
  });
}
