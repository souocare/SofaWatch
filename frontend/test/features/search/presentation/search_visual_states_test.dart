import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/search/presentation/widgets/search_empty_state.dart';
import 'package:sofawatch/features/search/presentation/widgets/search_failure_state.dart';
import 'package:sofawatch/features/search/presentation/widgets/search_loading_state.dart';

void main() {
  group('SearchLoadingState', () {
    testWidgets('shows the loading state', (WidgetTester tester) async {
      await _pumpWidget(tester, const SearchLoadingState());

      expect(
        find.byKey(const ValueKey<String>('search-loading-state')),
        findsOneWidget,
      );
    });

    testWidgets('supports the compact mobile variant', (
      WidgetTester tester,
    ) async {
      await _pumpWidget(tester, const SearchLoadingState(compact: true));

      expect(
        find.byKey(const ValueKey<String>('search-loading-state')),
        findsOneWidget,
      );
    });

    testWidgets('does not show an empty or failure state while loading', (
      WidgetTester tester,
    ) async {
      await _pumpWidget(tester, const SearchLoadingState());

      expect(
        find.byKey(const ValueKey<String>('search-empty-state')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('search-failure-state')),
        findsNothing,
      );
    });
  });

  group('SearchEmptyState', () {
    testWidgets('shows the searched query', (WidgetTester tester) async {
      await _pumpWidget(tester, const SearchEmptyState(query: 'Severance'));

      expect(
        find.byKey(const ValueKey<String>('search-empty-state')),
        findsOneWidget,
      );

      expect(find.text('No results for "Severance"'), findsOneWidget);
    });

    testWidgets('suggests changing the search or filter', (
      WidgetTester tester,
    ) async {
      await _pumpWidget(tester, const SearchEmptyState(query: 'Unknown title'));

      expect(
        find.text('Try another title or change the selected filter.'),
        findsOneWidget,
      );
    });
  });

  group('SearchFailureState', () {
    testWidgets('shows a safe connection error', (WidgetTester tester) async {
      await _pumpWidget(
        tester,
        SearchFailureState(
          error: const AppException.connection(),
          onRetry: () {},
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('search-failure-state')),
        findsOneWidget,
      );

      expect(find.text('Could not connect'), findsOneWidget);

      expect(
        find.text(
          'Check your connection to the SofaWatch server and try again.',
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('search-failure-retry')),
        findsOneWidget,
      );
    });

    testWidgets('shows a specific timeout error', (WidgetTester tester) async {
      await _pumpWidget(
        tester,
        SearchFailureState(
          error: const AppException.receiveTimeout(),
          onRetry: () {},
        ),
      );

      expect(find.text('Search took too long'), findsOneWidget);

      expect(
        find.text('The server did not respond in time. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('maps TMDB unavailable errors to safe provider copy', (
      WidgetTester tester,
    ) async {
      const String technicalMessage =
          'TMDB returned HTTP 503 with upstream response details';

      await _pumpWidget(
        tester,
        SearchFailureState(
          error: const AppException(
            type: AppExceptionType.server,
            code: 'tmdb_unavailable',
            message: technicalMessage,
          ),
          onRetry: () {},
        ),
      );

      expect(find.text('Search is temporarily unavailable'), findsOneWidget);

      expect(
        find.text(
          'The movie and TV information service is not responding right now.',
        ),
        findsOneWidget,
      );

      expect(find.text(technicalMessage), findsNothing);
    });

    testWidgets('maps an invalid TMDB response to a generic safe error', (
      WidgetTester tester,
    ) async {
      const String technicalMessage =
          'Unexpected JSON structure returned by TMDB';

      await _pumpWidget(
        tester,
        SearchFailureState(
          error: const AppException(
            type: AppExceptionType.invalidData,
            code: 'tmdb_invalid_response',
            message: technicalMessage,
          ),
          onRetry: () {},
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);

      expect(
        find.text('We could not process the search results. Please try again.'),
        findsOneWidget,
      );

      expect(find.text(technicalMessage), findsNothing);
    });

    testWidgets('uses a safe generic message for unexpected errors', (
      WidgetTester tester,
    ) async {
      const String technicalMessage =
          'Null check operator used on a null value';

      await _pumpWidget(
        tester,
        SearchFailureState(
          error: const AppException(
            type: AppExceptionType.unknown,
            message: technicalMessage,
          ),
          onRetry: () {},
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);

      expect(
        find.text('We could not complete the search. Please try again.'),
        findsOneWidget,
      );

      expect(find.text(technicalMessage), findsNothing);
    });

    testWidgets('calls retry when the Retry button is pressed', (
      WidgetTester tester,
    ) async {
      int retryCount = 0;

      await _pumpWidget(
        tester,
        SearchFailureState(
          error: const AppException.connection(),
          onRetry: () {
            retryCount++;
          },
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('search-failure-retry')),
      );

      await tester.pump();

      expect(retryCount, 1);
    });
  });
}

Future<void> _pumpWidget(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SizedBox(width: 700, height: 700, child: child)),
    ),
  );
}
