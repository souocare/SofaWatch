import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/core/state/remote_state.dart';
import 'package:sofawatch/features/search/application/bloc/search_bloc.dart';
import 'package:sofawatch/features/search/application/bloc/search_event.dart';
import 'package:sofawatch/features/search/application/bloc/search_state.dart';
import 'package:sofawatch/features/search/domain/entities/search_media_type.dart';
import 'package:sofawatch/features/search/domain/entities/search_result.dart';
import 'package:sofawatch/features/search/domain/models/search_media_type_filter.dart';
import 'package:sofawatch/features/search/domain/models/search_query.dart';
import 'package:sofawatch/features/search/domain/models/search_result_page.dart';
import 'package:sofawatch/features/search/domain/repositories/search_repository.dart';

typedef _SearchHandler = Future<SearchResultPage> Function(SearchQuery query);

final class _FakeSearchRepository implements SearchRepository {
  _FakeSearchRepository({_SearchHandler? handler})
    : _handler = handler ?? _defaultHandler;

  _SearchHandler _handler;

  final List<SearchQuery> receivedQueries = <SearchQuery>[];

  int get searchCallCount {
    return receivedQueries.length;
  }

  void setHandler(_SearchHandler handler) {
    _handler = handler;
  }

  @override
  Future<SearchResultPage> search(SearchQuery query) {
    receivedQueries.add(query);

    return _handler(query);
  }

  static Future<SearchResultPage> _defaultHandler(SearchQuery query) async {
    return _firstPage;
  }
}

void main() {
  group('SearchBloc', () {
    late _FakeSearchRepository repository;

    setUp(() {
      repository = _FakeSearchRepository();
    });

    test('starts with the initial state', () {
      final SearchBloc bloc = SearchBloc(repository);

      expect(bloc.state, const SearchState());

      bloc.close();
    });

    blocTest<SearchBloc, SearchState>(
      'updates the current query',
      build: () {
        return SearchBloc(repository);
      },
      act: (SearchBloc bloc) {
        bloc.add(const SearchQueryChanged('Dune'));
      },
      expect: () => <SearchState>[const SearchState(query: 'Dune')],
      verify: (SearchBloc bloc) {
        expect(repository.searchCallCount, 0);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'preserves surrounding whitespace in the UI query',
      build: () {
        return SearchBloc(repository);
      },
      act: (SearchBloc bloc) {
        bloc.add(const SearchQueryChanged('  Dune  '));
      },
      expect: () => <SearchState>[const SearchState(query: '  Dune  ')],
      verify: (SearchBloc bloc) {
        expect(bloc.state.normalizedQuery, 'Dune');
      },
    );

    blocTest<SearchBloc, SearchState>(
      'clears existing results when the query becomes empty',
      build: () {
        return SearchBloc(repository);
      },
      seed: () {
        return SearchState(
          query: 'Dune',
          mediaType: SearchMediaTypeFilter.movie,
          results: const RemoteState<SearchResultPage>.success(_firstPage),
        );
      },
      act: (SearchBloc bloc) {
        bloc.add(const SearchQueryChanged('   '));
      },
      expect: () => <SearchState>[
        const SearchState(query: '   ', mediaType: SearchMediaTypeFilter.movie),
      ],
      verify: (SearchBloc bloc) {
        expect(repository.searchCallCount, 0);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'emits loading and success when a search is submitted',
      build: () {
        return SearchBloc(repository);
      },
      seed: () {
        return const SearchState(query: 'Dune');
      },
      act: (SearchBloc bloc) {
        bloc.add(const SearchSubmitted());
      },
      expect: () => <SearchState>[
        const SearchState(
          query: 'Dune',
          results: RemoteState<SearchResultPage>.loading(),
        ),
        const SearchState(
          query: 'Dune',
          results: RemoteState<SearchResultPage>.success(_firstPage),
        ),
      ],
      verify: (SearchBloc bloc) {
        expect(repository.searchCallCount, 1);

        expect(
          repository.receivedQueries.single,
          const SearchQuery(term: 'Dune'),
        );
      },
    );

    blocTest<SearchBloc, SearchState>(
      'normalizes the query before submitting it',
      build: () {
        return SearchBloc(repository);
      },
      seed: () {
        return const SearchState(query: '  Dune  ');
      },
      act: (SearchBloc bloc) {
        bloc.add(const SearchSubmitted());
      },
      verify: (SearchBloc bloc) {
        expect(repository.receivedQueries.single.term, 'Dune');
      },
    );

    blocTest<SearchBloc, SearchState>(
      'does not search when submitting an empty query',
      build: () {
        return SearchBloc(repository);
      },
      seed: () {
        return const SearchState(
          query: '   ',
          mediaType: SearchMediaTypeFilter.movie,
          paginationError: AppException.connection(),
        );
      },
      act: (SearchBloc bloc) {
        bloc.add(const SearchSubmitted());
      },
      expect: () => <SearchState>[
        const SearchState(query: '   ', mediaType: SearchMediaTypeFilter.movie),
      ],
      verify: (SearchBloc bloc) {
        expect(repository.searchCallCount, 0);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'emits failure when the initial search fails',
      build: () {
        repository.setHandler((SearchQuery query) async {
          throw const AppException.connection();
        });

        return SearchBloc(repository);
      },
      seed: () {
        return const SearchState(query: 'Dune');
      },
      act: (SearchBloc bloc) {
        bloc.add(const SearchSubmitted());
      },
      expect: () => <SearchState>[
        const SearchState(
          query: 'Dune',
          results: RemoteState<SearchResultPage>.loading(),
        ),
        const SearchState(
          query: 'Dune',
          results: RemoteState<SearchResultPage>.failure(
            AppException.connection(),
          ),
        ),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'maps an unexpected repository error to unknown',
      build: () {
        repository.setHandler((SearchQuery query) async {
          throw StateError('Unexpected repository failure.');
        });

        return SearchBloc(repository);
      },
      seed: () {
        return const SearchState(query: 'Dune');
      },
      act: (SearchBloc bloc) {
        bloc.add(const SearchSubmitted());
      },
      expect: () => <Matcher>[
        isA<SearchState>().having(
          (SearchState state) => state.results.isLoading,
          'results loading',
          isTrue,
        ),
        isA<SearchState>()
            .having(
              (SearchState state) => state.results.isFailure,
              'results failure',
              isTrue,
            )
            .having(
              (SearchState state) => state.results.error?.type,
              'error type',
              AppExceptionType.unknown,
            ),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'changes the media type without searching when the query is empty',
      build: () {
        return SearchBloc(repository);
      },
      act: (SearchBloc bloc) {
        bloc.add(const SearchMediaTypeChanged(SearchMediaTypeFilter.movie));
      },
      expect: () => <SearchState>[
        const SearchState(mediaType: SearchMediaTypeFilter.movie),
      ],
      verify: (SearchBloc bloc) {
        expect(repository.searchCallCount, 0);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'does nothing when selecting the current media type',
      build: () {
        return SearchBloc(repository);
      },
      act: (SearchBloc bloc) {
        bloc.add(const SearchMediaTypeChanged(SearchMediaTypeFilter.all));
      },
      expect: () => <SearchState>[],
      verify: (SearchBloc bloc) {
        expect(repository.searchCallCount, 0);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'changes the media type and repeats an active search',
      build: () {
        return SearchBloc(repository);
      },
      seed: () {
        return const SearchState(query: 'Dune');
      },
      act: (SearchBloc bloc) {
        bloc.add(const SearchMediaTypeChanged(SearchMediaTypeFilter.movie));
      },
      expect: () => <SearchState>[
        const SearchState(
          query: 'Dune',
          mediaType: SearchMediaTypeFilter.movie,
        ),
        const SearchState(
          query: 'Dune',
          mediaType: SearchMediaTypeFilter.movie,
          results: RemoteState<SearchResultPage>.loading(),
        ),
        const SearchState(
          query: 'Dune',
          mediaType: SearchMediaTypeFilter.movie,
          results: RemoteState<SearchResultPage>.success(_firstPage),
        ),
      ],
      verify: (SearchBloc bloc) {
        expect(
          repository.receivedQueries.single,
          const SearchQuery(
            term: 'Dune',
            mediaType: SearchMediaTypeFilter.movie,
          ),
        );
      },
    );

    blocTest<SearchBloc, SearchState>(
      'loads and appends the next page',
      build: () {
        repository.setHandler((SearchQuery query) async {
          return _secondPage;
        });

        return SearchBloc(repository);
      },
      seed: () {
        return const SearchState(
          query: 'Dune',
          results: RemoteState<SearchResultPage>.success(_firstPage),
        );
      },
      act: (SearchBloc bloc) {
        bloc.add(const SearchNextPageRequested());
      },
      expect: () => <SearchState>[
        const SearchState(
          query: 'Dune',
          results: RemoteState<SearchResultPage>.success(_firstPage),
          isLoadingMore: true,
        ),
        SearchState(
          query: 'Dune',
          results: RemoteState<SearchResultPage>.success(
            _firstPage.append(_secondPage),
          ),
        ),
      ],
      verify: (SearchBloc bloc) {
        expect(
          repository.receivedQueries.single,
          const SearchQuery(term: 'Dune', page: 2),
        );
      },
    );

    blocTest<SearchBloc, SearchState>(
      'does not load more when there is no next page',
      build: () {
        return SearchBloc(repository);
      },
      seed: () {
        return const SearchState(
          query: 'Dune',
          results: RemoteState<SearchResultPage>.success(_finalPage),
        );
      },
      act: (SearchBloc bloc) {
        bloc.add(const SearchNextPageRequested());
      },
      expect: () => <SearchState>[],
      verify: (SearchBloc bloc) {
        expect(repository.searchCallCount, 0);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'preserves existing results when pagination fails',
      build: () {
        repository.setHandler((SearchQuery query) async {
          throw const AppException.connectionTimeout();
        });

        return SearchBloc(repository);
      },
      seed: () {
        return const SearchState(
          query: 'Dune',
          results: RemoteState<SearchResultPage>.success(_firstPage),
        );
      },
      act: (SearchBloc bloc) {
        bloc.add(const SearchNextPageRequested());
      },
      expect: () => <SearchState>[
        const SearchState(
          query: 'Dune',
          results: RemoteState<SearchResultPage>.success(_firstPage),
          isLoadingMore: true,
        ),
        const SearchState(
          query: 'Dune',
          results: RemoteState<SearchResultPage>.success(_firstPage),
          paginationError: AppException.connectionTimeout(),
        ),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'retries a failed pagination request',
      build: () {
        repository.setHandler((SearchQuery query) async {
          return _secondPage;
        });

        return SearchBloc(repository);
      },
      seed: () {
        return const SearchState(
          query: 'Dune',
          results: RemoteState<SearchResultPage>.success(_firstPage),
          paginationError: AppException.connectionTimeout(),
        );
      },
      act: (SearchBloc bloc) {
        bloc.add(const SearchRetryRequested());
      },
      expect: () => <SearchState>[
        const SearchState(
          query: 'Dune',
          results: RemoteState<SearchResultPage>.success(_firstPage),
          isLoadingMore: true,
        ),
        SearchState(
          query: 'Dune',
          results: RemoteState<SearchResultPage>.success(
            _firstPage.append(_secondPage),
          ),
        ),
      ],
      verify: (SearchBloc bloc) {
        expect(repository.receivedQueries.single.page, 2);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'retries a failed initial search',
      build: () {
        return SearchBloc(repository);
      },
      seed: () {
        return const SearchState(
          query: 'Dune',
          results: RemoteState<SearchResultPage>.failure(
            AppException.connection(),
          ),
        );
      },
      act: (SearchBloc bloc) {
        bloc.add(const SearchRetryRequested());
      },
      expect: () => <SearchState>[
        const SearchState(
          query: 'Dune',
          results: RemoteState<SearchResultPage>.loading(),
        ),
        const SearchState(
          query: 'Dune',
          results: RemoteState<SearchResultPage>.success(_firstPage),
        ),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'does not retry when there is no active query',
      build: () {
        return SearchBloc(repository);
      },
      act: (SearchBloc bloc) {
        bloc.add(const SearchRetryRequested());
      },
      expect: () => <SearchState>[],
      verify: (SearchBloc bloc) {
        expect(repository.searchCallCount, 0);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'clears the complete search state',
      build: () {
        return SearchBloc(repository);
      },
      seed: () {
        return const SearchState(
          query: 'Dune',
          mediaType: SearchMediaTypeFilter.movie,
          results: RemoteState<SearchResultPage>.success(_firstPage),
          isLoadingMore: true,
          paginationError: AppException.connection(),
        );
      },
      act: (SearchBloc bloc) {
        bloc.add(const SearchCleared());
      },
      expect: () => <SearchState>[const SearchState()],
    );

    test('ignores an older response after a newer search completes', () async {
      final Completer<SearchResultPage> duneCompleter =
          Completer<SearchResultPage>();

      final Completer<SearchResultPage> severanceCompleter =
          Completer<SearchResultPage>();

      repository.setHandler((SearchQuery query) {
        return switch (query.normalizedTerm) {
          'Dune' => duneCompleter.future,
          'Severance' => severanceCompleter.future,
          _ => throw StateError(
            'Unexpected search term: ${query.normalizedTerm}',
          ),
        };
      });

      final SearchBloc bloc = SearchBloc(repository);

      addTearDown(bloc.close);

      bloc.add(const SearchQueryChanged('Dune'));

      await _flushEventQueue();

      bloc.add(const SearchSubmitted());

      await _flushEventQueue();

      bloc.add(const SearchQueryChanged('Severance'));

      await _flushEventQueue();

      bloc.add(const SearchSubmitted());

      await _flushEventQueue();

      severanceCompleter.complete(_severancePage);

      await _flushEventQueue();

      expect(bloc.state.results.data?.results.single.title, 'Severance');

      duneCompleter.complete(_firstPage);

      await _flushEventQueue();

      expect(bloc.state.results.data?.results.single.title, 'Severance');

      expect(repository.searchCallCount, 2);
    });

    test('ignores an active response after the search is cleared', () async {
      final Completer<SearchResultPage> completer =
          Completer<SearchResultPage>();

      repository.setHandler((SearchQuery query) {
        return completer.future;
      });

      final SearchBloc bloc = SearchBloc(repository);

      addTearDown(bloc.close);

      bloc.add(const SearchQueryChanged('Dune'));

      await _flushEventQueue();

      bloc.add(const SearchSubmitted());

      await _flushEventQueue();

      expect(bloc.state.results.isLoading, isTrue);

      bloc.add(const SearchCleared());

      await _flushEventQueue();

      expect(bloc.state, const SearchState());

      completer.complete(_firstPage);

      await _flushEventQueue();

      expect(bloc.state, const SearchState());
    });
  });
}

Future<void> _flushEventQueue() async {
  await Future<void>.delayed(Duration.zero);

  await Future<void>.delayed(Duration.zero);
}

const SearchResult _duneResult = SearchResult(
  mediaType: SearchMediaType.movie,
  tmdbId: 438631,
  title: 'Dune',
  originalTitle: 'Dune',
  originalLanguage: 'en',
  genreIds: <int>[878, 12],
  popularity: 95.4,
  voteAverage: 7.8,
  voteCount: 13000,
);

const SearchResult _bladeRunnerResult = SearchResult(
  mediaType: SearchMediaType.movie,
  tmdbId: 78,
  title: 'Blade Runner',
  originalTitle: 'Blade Runner',
  originalLanguage: 'en',
  genreIds: <int>[878, 18],
  popularity: 80,
  voteAverage: 7.9,
  voteCount: 14000,
);

const SearchResult _severanceResult = SearchResult(
  mediaType: SearchMediaType.show,
  tmdbId: 95396,
  title: 'Severance',
  originalTitle: 'Severance',
  originalLanguage: 'en',
  genreIds: <int>[18, 9648],
  popularity: 120.5,
  voteAverage: 8.4,
  voteCount: 2100,
);

const SearchResultPage _firstPage = SearchResultPage(
  page: 1,
  results: <SearchResult>[_duneResult],
  totalPages: 2,
  totalResults: 2,
);

const SearchResultPage _secondPage = SearchResultPage(
  page: 2,
  results: <SearchResult>[_bladeRunnerResult],
  totalPages: 2,
  totalResults: 2,
);

const SearchResultPage _finalPage = SearchResultPage(
  page: 1,
  results: <SearchResult>[_duneResult],
  totalPages: 1,
  totalResults: 1,
);

const SearchResultPage _severancePage = SearchResultPage(
  page: 1,
  results: <SearchResult>[_severanceResult],
  totalPages: 1,
  totalResults: 1,
);
