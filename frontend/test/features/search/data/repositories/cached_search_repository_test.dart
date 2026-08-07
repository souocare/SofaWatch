import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/search/data/cache/in_memory_search_cache.dart';
import 'package:sofawatch/features/search/data/repositories/cached_search_repository.dart';
import 'package:sofawatch/features/search/domain/models/search_media_type_filter.dart';
import 'package:sofawatch/features/search/domain/models/search_query.dart';
import 'package:sofawatch/features/search/domain/models/search_result_page.dart';
import 'package:sofawatch/features/search/domain/repositories/search_repository.dart';

void main() {
  group('CachedSearchRepository', () {
    late _FakeSearchRepository sourceRepository;
    late CachedSearchRepository repository;

    setUp(() {
      sourceRepository = _FakeSearchRepository();

      repository = CachedSearchRepository(
        repository: sourceRepository,
        cache: InMemorySearchCache(),
      );
    });

    test('uses the source repository on a cache miss', () async {
      await repository.search(const SearchQuery(term: 'Severance'));

      expect(sourceRepository.requestCount, 1);
    });

    test('reuses the cached result for an equivalent query', () async {
      final SearchResultPage firstResult = await repository.search(
        const SearchQuery(term: ' Severance '),
      );

      final SearchResultPage secondResult = await repository.search(
        const SearchQuery(term: 'SEVERANCE'),
      );

      expect(secondResult, firstResult);
      expect(sourceRepository.requestCount, 1);
    });

    test('uses separate cache entries for different filters', () async {
      await repository.search(
        const SearchQuery(
          term: 'Severance',
          mediaType: SearchMediaTypeFilter.show,
        ),
      );

      await repository.search(
        const SearchQuery(
          term: 'Severance',
          mediaType: SearchMediaTypeFilter.movie,
        ),
      );

      expect(sourceRepository.requestCount, 2);
    });

    test('uses separate cache entries for different pages', () async {
      await repository.search(const SearchQuery(term: 'Severance', page: 1));

      await repository.search(const SearchQuery(term: 'Severance', page: 2));

      expect(sourceRepository.requestCount, 2);
    });

    test('uses separate cache entries for different languages', () async {
      await repository.search(
        const SearchQuery(term: 'Severance', language: 'en-US'),
      );

      await repository.search(
        const SearchQuery(term: 'Severance', language: 'pt-PT'),
      );

      expect(sourceRepository.requestCount, 2);
    });

    test(
      'clearCache forces the next search to use the source repository',
      () async {
        const SearchQuery query = SearchQuery(term: 'Severance');

        await repository.search(query);

        repository.clearCache();

        await repository.search(query);

        expect(sourceRepository.requestCount, 2);
      },
    );

    test('does not cache failures', () async {
      sourceRepository.shouldFail = true;

      const SearchQuery query = SearchQuery(term: 'Severance');

      await expectLater(repository.search(query), throwsA(isA<StateError>()));

      sourceRepository.shouldFail = false;

      await repository.search(query);

      expect(sourceRepository.requestCount, 2);
    });

    test(
      'deduplicates identical requests that are already in flight',
      () async {
        final Completer<SearchResultPage> completer =
            Completer<SearchResultPage>();

        sourceRepository.pendingResult = completer;

        const SearchQuery query = SearchQuery(term: 'Severance');

        final Future<SearchResultPage> firstRequest = repository.search(query);
        final Future<SearchResultPage> secondRequest = repository.search(query);

        expect(sourceRepository.requestCount, 1);

        completer.complete(_FakeSearchRepository.resultPage);

        final List<SearchResultPage> results =
            await Future.wait<SearchResultPage>(<Future<SearchResultPage>>[
              firstRequest,
              secondRequest,
            ]);

        expect(results[0], results[1]);
        expect(sourceRepository.requestCount, 1);
      },
    );
  });
}

final class _FakeSearchRepository implements SearchRepository {
  static const SearchResultPage resultPage = SearchResultPage(
    page: 1,
    results: [],
    totalPages: 1,
    totalResults: 0,
  );

  int requestCount = 0;
  bool shouldFail = false;
  Completer<SearchResultPage>? pendingResult;

  @override
  Future<SearchResultPage> search(SearchQuery query) {
    requestCount++;

    if (shouldFail) {
      return Future<SearchResultPage>.error(StateError('Search failed'));
    }

    final Completer<SearchResultPage>? currentPendingResult = pendingResult;

    if (currentPendingResult != null) {
      return currentPendingResult.future;
    }

    return Future<SearchResultPage>.value(resultPage);
  }
}
