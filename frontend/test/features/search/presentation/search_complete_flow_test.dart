@TestOn('browser')
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/app/app_bootstrap_data.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/features/search/domain/entities/search_media_type.dart';
import 'package:sofawatch/features/search/domain/entities/search_result.dart';
import 'package:sofawatch/features/search/domain/models/search_media_type_filter.dart';
import 'package:sofawatch/features/search/domain/models/search_result_page.dart';

import '../../../fakes/fake_search_repository.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_bootstrap_data.dart';

const SearchResult _movieResult = SearchResult(
  mediaType: SearchMediaType.movie,
  tmdbId: 438631,
  title: 'Dune',
  originalTitle: 'Dune',
  originalLanguage: 'en',
  genreIds: <int>[878, 12],
  popularity: 100,
  voteAverage: 7.8,
  voteCount: 13000,
);

void main() {
  testWidgets('completes the main Search flow from query to Watchlist', (
    WidgetTester tester,
  ) async {
    final FakeSearchRepository searchRepository = FakeSearchRepository(
      result: const SearchResultPage(
        page: 1,
        results: <SearchResult>[_movieResult],
        totalPages: 1,
        totalResults: 1,
      ),
    );

    final Dio dio = Dio();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          if (options.method == 'GET' &&
              options.path.endsWith('/movies/tmdb/438631')) {
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: _movieDetailsResponse,
              ),
            );
            return;
          }

          if (options.method == 'POST' &&
              options.path.endsWith('/movies/import/tmdb/438631')) {
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: const <String, dynamic>{
                  'id': 'movie-uuid',
                  'tmdb_id': 438631,
                },
              ),
            );
            return;
          }

          if (options.method == 'POST' &&
              options.path.endsWith('/library/movies/movie-uuid')) {
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: const <String, dynamic>{
                  'id': 'library-entry-uuid',
                  'show_id': null,
                  'movie_id': 'movie-uuid',
                  'status': 'planning',
                  'rating': null,
                  'started_at': null,
                  'completed_at': null,
                  'created_at': '2026-08-08T20:00:00Z',
                  'updated_at': '2026-08-08T20:00:00Z',
                },
              ),
            );
            return;
          }

          handler.next(options);
        },
      ),
    );

    final ApiClient apiClient = ApiClient(
      baseUrl: Uri.parse('http://localhost:8000'),
      dio: dio,
    );

    final AppBootstrapData bootstrapData = createTestBootstrapData(
      searchRepository: searchRepository,
      apiClient: apiClient,
    );

    await tester.pumpSofaWatchWebApp(
      bootstrapData: bootstrapData,
      surfaceSize: const Size(1280, 900),
    );

    // 13.15.16.1 — Open Search.
    expect(
      find.byKey(const ValueKey<String>('home-page-title')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('web-search-action')));

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('search-desktop-modal')),
      findsOneWidget,
    );

    // 13.15.16.2 — Enter query.
    final Finder searchField = find.byKey(
      const ValueKey<String>('search-text-field'),
    );

    expect(searchField, findsOneWidget);

    await tester.enterText(searchField, 'Dune');

    // 13.15.16.3 — Wait for the 350 ms debounce.
    await tester.pump(const Duration(milliseconds: 400));

    await tester.pumpAndSettle();

    // 13.15.16.4 — Results are displayed.
    final Finder duneResult = find.byKey(
      const ValueKey<String>('search-result-movie-438631'),
    );

    expect(duneResult, findsOneWidget);

    expect(searchRepository.searchCallCount, 1);

    // 13.15.16.5 — Change filter.
    await tester.tap(find.byKey(const ValueKey<String>('search-filter-movie')));

    await tester.pumpAndSettle();

    expect(searchRepository.searchCallCount, 2);

    expect(searchRepository.lastQuery?.mediaType, SearchMediaTypeFilter.movie);

    expect(duneResult, findsOneWidget);

    // 13.15.16.6 — Open preview.
    await tester.tap(duneResult);

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('movie-details-content')),
      findsOneWidget,
    );

    expect(
      find.byKey(const ValueKey<String>('movie-details-title')),
      findsOneWidget,
    );

    // 13.15.16.7 — Close preview.
    await tester.tap(
      find.byKey(const ValueKey<String>('movie-details-close-button')),
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('search-desktop-modal')),
      findsOneWidget,
    );

    expect(duneResult, findsOneWidget);

    final TextField fieldAfterPreview = tester.widget<TextField>(searchField);

    expect(fieldAfterPreview.controller?.text, 'Dune');

    expect(
      searchRepository.searchCallCount,
      2,
      reason: 'Closing the preview must not repeat the Search.',
    );

    // 13.15.16.8 — Add Movie to Watchlist.
    final Finder action = find.byKey(
      const ValueKey<String>('search-result-action-movie-438631'),
    );

    expect(action, findsOneWidget);

    await tester.tap(action);

    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey<String>('search-result-action-added-movie-438631'),
      ),
      findsOneWidget,
    );

    expect(find.text('Added'), findsOneWidget);

    expect(
      duneResult,
      findsOneWidget,
      reason: 'Adding to Watchlist must keep the Search result visible.',
    );

    expect(
      searchRepository.searchCallCount,
      2,
      reason: 'Adding to Watchlist must not trigger another Search.',
    );

    // 13.15.16.9 — Close Search.
    await tester.tap(
      find.byKey(const ValueKey<String>('search-desktop-close-button')),
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('search-desktop-modal')),
      findsNothing,
    );

    expect(
      find.byKey(const ValueKey<String>('home-page-title')),
      findsOneWidget,
    );
  });
}

const Map<String, dynamic> _movieDetailsResponse = <String, dynamic>{
  'tmdb_id': 438631,
  'title': 'Dune',
  'original_title': 'Dune',
  'overview': 'Paul Atreides travels to Arrakis.',
  'tagline': 'Beyond fear, destiny awaits.',
  'release_date': '2021-09-15',
  'poster_url': null,
  'backdrop_url': null,
  'genres': <Map<String, dynamic>>[
    <String, dynamic>{'tmdb_id': 878, 'name': 'Science Fiction'},
  ],
  'original_language': 'en',
  'runtime': 155,
  'status': 'Released',
  'vote_average': 7.8,
  'vote_count': 13000,
};
