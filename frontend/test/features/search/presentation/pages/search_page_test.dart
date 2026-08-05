import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/app/theme/tokens/app_breakpoints.dart';
import 'package:sofawatch/features/search/application/bloc/search_bloc.dart';
import 'package:sofawatch/features/search/domain/models/search_query.dart';
import 'package:sofawatch/features/search/domain/models/search_result_page.dart';
import 'package:sofawatch/features/search/domain/repositories/search_repository.dart';
import 'package:sofawatch/features/search/presentation/pages/search_page.dart';

final class _FakeSearchRepository implements SearchRepository {
  @override
  Future<SearchResultPage> search(SearchQuery query) async {
    return const SearchResultPage(
      page: 1,
      results: [],
      totalPages: 0,
      totalResults: 0,
    );
  }
}

void main() {
  group('SearchPage', () {
    testWidgets('shows the mobile view below the tablet breakpoint', (
      WidgetTester tester,
    ) async {
      await _setSurfaceSize(tester, const Size(390, 844));

      await tester.pumpWidget(_buildSearchPage());

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('search-mobile-view')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('search-desktop-modal')),
        findsNothing,
      );
    });

    testWidgets('does not show a duplicated search field on mobile', (
      WidgetTester tester,
    ) async {
      await _setSurfaceSize(tester, const Size(390, 844));

      await tester.pumpWidget(_buildSearchPage());

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('search-mobile-title')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('search-text-field')),
        findsNothing,
      );
    });

    testWidgets('shows the desktop view at the tablet breakpoint', (
      WidgetTester tester,
    ) async {
      await _setSurfaceSize(tester, const Size(AppBreakpoints.tablet, 844));

      await tester.pumpWidget(_buildSearchPage());

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('search-desktop-modal')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('search-mobile-view')),
        findsNothing,
      );
    });

    testWidgets('shows the reusable search field on desktop', (
      WidgetTester tester,
    ) async {
      await _setSurfaceSize(tester, const Size(1200, 844));

      await tester.pumpWidget(_buildSearchPage());

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('search-text-field')),
        findsOneWidget,
      );
    });

    testWidgets('focuses the desktop search field automatically', (
      WidgetTester tester,
    ) async {
      await _setSurfaceSize(tester, const Size(1200, 844));

      await tester.pumpWidget(_buildSearchPage());

      await tester.pumpAndSettle();

      final EditableText editableText = tester.widget<EditableText>(
        find.byType(EditableText),
      );

      expect(editableText.focusNode.hasFocus, isTrue);
    });
  });
}

Widget _buildSearchPage() {
  return MaterialApp(
    home: BlocProvider<SearchBloc>(
      create: (BuildContext context) {
        return SearchBloc(_FakeSearchRepository());
      },
      child: const SearchPage(),
    ),
  );
}

Future<void> _setSurfaceSize(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);

  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });
}
