import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/search/domain/models/search_media_type_filter.dart';
import 'package:sofawatch/features/search/presentation/widgets/search_media_type_filter_bar.dart';

void main() {
  group('SearchMediaTypeFilterBar', () {
    testWidgets('shows All, Shows and Movies', (WidgetTester tester) async {
      await _pumpFilterBar(tester);

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Shows'), findsOneWidget);
      expect(find.text('Movies'), findsOneWidget);
    });

    testWidgets('reflects the selected filter', (WidgetTester tester) async {
      await _pumpFilterBar(tester, selectedFilter: SearchMediaTypeFilter.show);

      final Semantics showsSemantics = tester.widget<Semantics>(
        find
            .ancestor(
              of: find.byKey(const ValueKey<String>('search-filter-show')),
              matching: find.byType(Semantics),
            )
            .first,
      );

      expect(showsSemantics.properties.selected, isTrue);
    });

    testWidgets('reports the selected filter when tapped', (
      WidgetTester tester,
    ) async {
      SearchMediaTypeFilter? selectedFilter;

      await _pumpFilterBar(
        tester,
        onFilterChanged: (SearchMediaTypeFilter filter) {
          selectedFilter = filter;
        },
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('search-filter-movie')),
      );

      await tester.pump();

      expect(selectedFilter, SearchMediaTypeFilter.movie);
    });

    testWidgets('uses a horizontally scrollable container', (
      WidgetTester tester,
    ) async {
      await _pumpFilterBar(tester, surfaceSize: const Size(220, 300));

      final SingleChildScrollView scrollView = tester
          .widget<SingleChildScrollView>(
            find.byKey(
              const ValueKey<String>('search-media-type-filter-scroll'),
            ),
          );

      expect(scrollView.scrollDirection, Axis.horizontal);
    });

    testWidgets('supports compact presentation', (WidgetTester tester) async {
      await _pumpFilterBar(tester, compact: true);

      expect(
        find.byKey(const ValueKey<String>('search-media-type-filter-bar')),
        findsOneWidget,
      );
    });
  });
}

Future<void> _pumpFilterBar(
  WidgetTester tester, {
  SearchMediaTypeFilter selectedFilter = SearchMediaTypeFilter.all,
  ValueChanged<SearchMediaTypeFilter>? onFilterChanged,
  bool compact = false,
  Size surfaceSize = const Size(600, 300),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);

  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SearchMediaTypeFilterBar(
          selectedFilter: selectedFilter,
          compact: compact,
          onFilterChanged: onFilterChanged ?? (_) {},
        ),
      ),
    ),
  );
}
