import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/shows/application/cubit/shows_cubit.dart';
import 'package:sofawatch/features/shows/application/cubit/shows_state.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';
import 'package:sofawatch/features/shows/domain/models/stale_watching_episode.dart';
import 'package:sofawatch/features/shows/domain/models/stale_watching_show.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_episode.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_item.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_page.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_episode.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_show.dart';
import 'package:sofawatch/features/shows/domain/repositories/shows_repository.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_progress.dart';

void main() {
  group('ShowsCubit', () {
    test('starts with an empty Shows state', () {
      final ShowsCubit cubit = ShowsCubit(repository: _FakeShowsRepository());

      expect(cubit.state, const ShowsState());

      cubit.close();
    });

    test('loads Library, Watch Next and stale Watching', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        shows: <LibraryShow>[
          _libraryShow(
            tmdbId: 95396,
            title: 'Severance',
            status: LibraryStatus.watching,
          ),
        ],
        watchNext: <WatchNextShow>[_watchNextShow()],
        staleWatching: <StaleWatchingShow>[_staleWatchingShow()],
      );

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      await cubit.load();

      expect(repository.libraryCalls, 1);
      expect(repository.watchNextCalls, 1);
      expect(repository.staleWatchingCalls, 1);

      expect(cubit.state.libraryShows, repository.shows);

      expect(cubit.state.watchNext, repository.watchNext);

      expect(cubit.state.staleWatching, repository.staleWatching);

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.error, isNull);
      expect(cubit.state.watchNextError, isNull);
      expect(cubit.state.staleWatchingError, isNull);

      await cubit.close();
    });

    test('supports empty Library and supplementary collections', () async {
      final ShowsCubit cubit = ShowsCubit(repository: _FakeShowsRepository());

      await cubit.load();

      expect(cubit.state.libraryShows, isEmpty);
      expect(cubit.state.watchNext, isEmpty);
      expect(cubit.state.staleWatching, isEmpty);

      expect(cubit.state.isLibraryEmpty, isTrue);
      expect(cubit.state.isWatchNextEmpty, isTrue);
      expect(cubit.state.isStaleWatchingEmpty, isTrue);

      await cubit.close();
    });

    test(
      'does not load supplementary sections when Library loading fails',
      () async {
        const AppException expectedError = AppException.connection();

        final _FakeShowsRepository repository = _FakeShowsRepository(
          libraryError: expectedError,
        );

        final ShowsCubit cubit = ShowsCubit(repository: repository);

        await cubit.load();

        expect(repository.libraryCalls, 1);
        expect(repository.watchNextCalls, 0);
        expect(repository.staleWatchingCalls, 0);

        expect(cubit.state.error, expectedError);
        expect(cubit.state.hasFatalError, isTrue);

        await cubit.close();
      },
    );

    test('maps unexpected Library errors to unknown failure', () async {
      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(
          libraryUnexpectedError: StateError('boom'),
        ),
      );

      await cubit.load();

      expect(cubit.state.error?.type, AppExceptionType.unknown);

      await cubit.close();
    });

    test(
      'preserves Library and loads stale Watching when Watch Next fails',
      () async {
        const AppException expectedError = AppException.connection();

        final _FakeShowsRepository repository = _FakeShowsRepository(
          shows: <LibraryShow>[
            _libraryShow(
              tmdbId: 95396,
              title: 'Severance',
              status: LibraryStatus.watching,
            ),
          ],
          watchNextError: expectedError,
          staleWatching: <StaleWatchingShow>[_staleWatchingShow()],
        );

        final ShowsCubit cubit = ShowsCubit(repository: repository);

        await cubit.load();

        expect(cubit.state.libraryShows, hasLength(1));
        expect(cubit.state.error, isNull);

        expect(cubit.state.watchNextError, expectedError);

        expect(cubit.state.watchNext, isEmpty);

        expect(repository.staleWatchingCalls, 1);

        expect(cubit.state.staleWatching, hasLength(1));

        expect(cubit.state.staleWatchingError, isNull);

        await cubit.close();
      },
    );

    test(
      'maps unexpected Watch Next errors without failing the page',
      () async {
        final ShowsCubit cubit = ShowsCubit(
          repository: _FakeShowsRepository(
            shows: <LibraryShow>[
              _libraryShow(
                tmdbId: 95396,
                title: 'Severance',
                status: LibraryStatus.watching,
              ),
            ],
            watchNextUnexpectedError: StateError('boom'),
          ),
        );

        await cubit.load();

        expect(cubit.state.error, isNull);

        expect(cubit.state.watchNextError?.type, AppExceptionType.unknown);

        expect(cubit.state.libraryShows, hasLength(1));

        await cubit.close();
      },
    );

    test(
      'preserves Library and Watch Next when stale Watching fails',
      () async {
        const AppException expectedError = AppException.connection();

        final _FakeShowsRepository repository = _FakeShowsRepository(
          shows: <LibraryShow>[
            _libraryShow(
              tmdbId: 95396,
              title: 'Severance',
              status: LibraryStatus.watching,
            ),
          ],
          watchNext: <WatchNextShow>[_watchNextShow()],
          staleWatchingError: expectedError,
        );

        final ShowsCubit cubit = ShowsCubit(repository: repository);

        await cubit.load();

        expect(cubit.state.error, isNull);
        expect(cubit.state.libraryShows, hasLength(1));
        expect(cubit.state.watchNext, hasLength(1));

        expect(cubit.state.staleWatching, isEmpty);

        expect(cubit.state.staleWatchingError, expectedError);

        await cubit.close();
      },
    );

    test(
      'maps unexpected stale Watching errors without failing the page',
      () async {
        final ShowsCubit cubit = ShowsCubit(
          repository: _FakeShowsRepository(
            shows: <LibraryShow>[
              _libraryShow(
                tmdbId: 95396,
                title: 'Severance',
                status: LibraryStatus.watching,
              ),
            ],
            staleWatchingUnexpectedError: StateError('boom'),
          ),
        );

        await cubit.load();

        expect(cubit.state.error, isNull);

        expect(cubit.state.staleWatchingError?.type, AppExceptionType.unknown);

        expect(cubit.state.libraryShows, hasLength(1));

        await cubit.close();
      },
    );

    test('retry reloads Library and all supplementary sections', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        shows: <LibraryShow>[
          _libraryShow(
            tmdbId: 95396,
            title: 'Severance',
            status: LibraryStatus.watching,
          ),
        ],
        watchNext: <WatchNextShow>[_watchNextShow()],
        staleWatching: <StaleWatchingShow>[_staleWatchingShow()],
      );

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      await cubit.load();

      expect(repository.libraryCalls, 1);
      expect(repository.watchNextCalls, 1);
      expect(repository.staleWatchingCalls, 1);

      await cubit.retry();

      expect(repository.libraryCalls, 2);
      expect(repository.watchNextCalls, 2);
      expect(repository.staleWatchingCalls, 2);

      await cubit.close();
    });

    test('retryWatchNext reloads only Watch Next', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        shows: <LibraryShow>[
          _libraryShow(
            tmdbId: 95396,
            title: 'Severance',
            status: LibraryStatus.watching,
          ),
        ],
        watchNext: <WatchNextShow>[_watchNextShow()],
        staleWatching: <StaleWatchingShow>[_staleWatchingShow()],
      );

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      await cubit.load();

      expect(repository.libraryCalls, 1);
      expect(repository.watchNextCalls, 1);
      expect(repository.staleWatchingCalls, 1);

      await cubit.retryWatchNext();

      expect(repository.libraryCalls, 1);
      expect(repository.watchNextCalls, 2);
      expect(repository.staleWatchingCalls, 1);

      await cubit.close();
    });

    test('retryStaleWatching reloads only stale Watching', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        shows: <LibraryShow>[
          _libraryShow(
            tmdbId: 95396,
            title: 'Severance',
            status: LibraryStatus.watching,
          ),
        ],
        watchNext: <WatchNextShow>[_watchNextShow()],
        staleWatching: <StaleWatchingShow>[_staleWatchingShow()],
      );

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      await cubit.load();

      expect(repository.libraryCalls, 1);
      expect(repository.watchNextCalls, 1);
      expect(repository.staleWatchingCalls, 1);

      await cubit.retryStaleWatching();

      expect(repository.libraryCalls, 1);
      expect(repository.watchNextCalls, 1);
      expect(repository.staleWatchingCalls, 2);

      await cubit.close();
    });
    test('derives Haven\'t Started from planning Library Shows', () async {
      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(
          shows: <LibraryShow>[
            _libraryShow(
              tmdbId: 95396,
              title: 'Severance',
              status: LibraryStatus.watching,
            ),
            _libraryShow(
              tmdbId: 1396,
              title: 'Breaking Bad',
              status: LibraryStatus.planning,
            ),
            _libraryShow(
              tmdbId: 100088,
              title: 'The Last of Us',
              status: LibraryStatus.planning,
            ),
          ],
        ),
      );

      await cubit.load();

      expect(
        cubit.state.haventStarted.map((LibraryShow show) => show.tmdbId),
        <int>[1396, 100088],
      );

      expect(cubit.state.isHaventStartedEmpty, isFalse);

      await cubit.close();
    });

    test('Haven\'t Started is empty without planning Shows', () async {
      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(
          shows: <LibraryShow>[
            _libraryShow(
              tmdbId: 95396,
              title: 'Severance',
              status: LibraryStatus.watching,
            ),
          ],
        ),
      );

      await cubit.load();

      expect(cubit.state.haventStarted, isEmpty);

      expect(cubit.state.isHaventStartedEmpty, isTrue);

      await cubit.close();
    });
    test('loads the first Watch History page', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        watchHistoryPages: <WatchHistoryPage>[
          WatchHistoryPage(
            items: <WatchHistoryItem>[
              _watchHistoryItem(
                episodeId: 'episode-1',
                episodeNumber: 4,
                title: "Woe's Hollow",
              ),
            ],
            nextCursor: 'cursor-1',
            hasMore: true,
          ),
        ],
      );

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      await cubit.loadWatchHistory();

      expect(repository.watchHistoryCalls, 1);
      expect(repository.watchHistoryCursors, <String?>[null]);

      expect(cubit.state.watchHistory, hasLength(1));
      expect(cubit.state.watchHistory.single.episode.id, 'episode-1');

      expect(cubit.state.watchHistoryNextCursor, 'cursor-1');
      expect(cubit.state.hasMoreWatchHistory, isTrue);
      expect(cubit.state.isLoadingWatchHistory, isFalse);
      expect(cubit.state.isLoadingMoreWatchHistory, isFalse);
      expect(cubit.state.watchHistoryError, isNull);
      expect(cubit.state.hasLoadedWatchHistory, isTrue);

      await cubit.close();
    });

    test('loads and appends the next Watch History page', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        watchHistoryPages: <WatchHistoryPage>[
          WatchHistoryPage(
            items: <WatchHistoryItem>[
              _watchHistoryItem(
                episodeId: 'episode-1',
                episodeNumber: 4,
                title: "Woe's Hollow",
              ),
            ],
            nextCursor: 'cursor-1',
            hasMore: true,
          ),
          WatchHistoryPage(
            items: <WatchHistoryItem>[
              _watchHistoryItem(
                episodeId: 'episode-2',
                episodeNumber: 3,
                title: 'Who Is Alive?',
              ),
            ],
            nextCursor: null,
            hasMore: false,
          ),
        ],
      );

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      await cubit.loadWatchHistory();
      await cubit.loadMoreWatchHistory();

      expect(repository.watchHistoryCalls, 2);

      expect(repository.watchHistoryCursors, <String?>[null, 'cursor-1']);

      expect(cubit.state.watchHistory, hasLength(2));

      expect(
        cubit.state.watchHistory.map(
          (WatchHistoryItem item) => item.episode.id,
        ),
        <String>['episode-1', 'episode-2'],
      );

      expect(cubit.state.watchHistoryNextCursor, isNull);
      expect(cubit.state.hasMoreWatchHistory, isFalse);
      expect(cubit.state.isLoadingMoreWatchHistory, isFalse);

      await cubit.close();
    });

    test('does not load more Watch History when no more pages exist', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        watchHistoryPages: <WatchHistoryPage>[
          WatchHistoryPage(
            items: <WatchHistoryItem>[
              _watchHistoryItem(
                episodeId: 'episode-1',
                episodeNumber: 4,
                title: "Woe's Hollow",
              ),
            ],
            nextCursor: null,
            hasMore: false,
          ),
        ],
      );

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      await cubit.loadWatchHistory();

      expect(repository.watchHistoryCalls, 1);
      expect(cubit.state.hasMoreWatchHistory, isFalse);

      await cubit.loadMoreWatchHistory();

      expect(
        repository.watchHistoryCalls,
        1,
        reason: 'No request should be made after the last History page.',
      );

      await cubit.close();
    });

    test('preserves loaded Watch History when loading more fails', () async {
      const AppException expectedError = AppException.connection();

      final _FakeShowsRepository repository = _FakeShowsRepository(
        watchHistoryPages: <WatchHistoryPage>[
          WatchHistoryPage(
            items: <WatchHistoryItem>[
              _watchHistoryItem(
                episodeId: 'episode-1',
                episodeNumber: 4,
                title: "Woe's Hollow",
              ),
            ],
            nextCursor: 'cursor-1',
            hasMore: true,
          ),
        ],
        watchHistoryErrors: <AppException?>[null, expectedError],
      );

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      await cubit.loadWatchHistory();
      await cubit.loadMoreWatchHistory();

      expect(repository.watchHistoryCalls, 2);

      expect(cubit.state.watchHistory, hasLength(1));
      expect(cubit.state.watchHistory.single.episode.id, 'episode-1');

      expect(
        cubit.state.watchHistoryNextCursor,
        'cursor-1',
        reason: 'A failed page must keep the cursor so the user can retry.',
      );

      expect(cubit.state.hasMoreWatchHistory, isTrue);
      expect(cubit.state.watchHistoryError, expectedError);
      expect(cubit.state.isLoadingMoreWatchHistory, isFalse);

      await cubit.close();
    });

    test('maps unexpected Watch History errors to unknown', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        watchHistoryUnexpectedErrors: <Object?>[StateError('boom')],
      );

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      await cubit.loadWatchHistory();

      expect(cubit.state.watchHistoryError?.type, AppExceptionType.unknown);

      expect(cubit.state.watchHistory, isEmpty);
      expect(cubit.state.isLoadingWatchHistory, isFalse);
      expect(cubit.state.hasLoadedWatchHistory, isFalse);

      await cubit.close();
    });

    test('does not start duplicate initial Watch History requests', () async {
      final _PendingWatchHistoryRepository repository =
          _PendingWatchHistoryRepository();

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      final Future<void> firstLoad = cubit.loadWatchHistory();

      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.isLoadingWatchHistory, isTrue);
      expect(repository.watchHistoryCalls, 1);

      final Future<void> secondLoad = cubit.loadWatchHistory();

      await Future<void>.delayed(Duration.zero);

      expect(
        repository.watchHistoryCalls,
        1,
        reason: 'A second request must not start while the first is pending.',
      );

      repository.complete(
        const WatchHistoryPage(
          items: <WatchHistoryItem>[],
          nextCursor: null,
          hasMore: false,
        ),
      );

      await firstLoad;
      await secondLoad;

      expect(cubit.state.isLoadingWatchHistory, isFalse);

      await cubit.close();
    });

    test(
      'does not start duplicate Watch History pagination requests',
      () async {
        final _PendingLoadMoreWatchHistoryRepository repository =
            _PendingLoadMoreWatchHistoryRepository();

        final ShowsCubit cubit = ShowsCubit(repository: repository);

        await cubit.loadWatchHistory();

        expect(cubit.state.hasMoreWatchHistory, isTrue);
        expect(cubit.state.watchHistoryNextCursor, 'cursor-1');

        final Future<void> firstLoadMore = cubit.loadMoreWatchHistory();

        await Future<void>.delayed(Duration.zero);

        expect(cubit.state.isLoadingMoreWatchHistory, isTrue);
        expect(repository.watchHistoryCalls, 2);

        final Future<void> secondLoadMore = cubit.loadMoreWatchHistory();

        await Future<void>.delayed(Duration.zero);

        expect(
          repository.watchHistoryCalls,
          2,
          reason: 'Only one pagination request may run at a time.',
        );

        repository.completeLoadMore(
          const WatchHistoryPage(
            items: <WatchHistoryItem>[],
            nextCursor: null,
            hasMore: false,
          ),
        );

        await firstLoadMore;
        await secondLoadMore;

        expect(cubit.state.isLoadingMoreWatchHistory, isFalse);

        await cubit.close();
      },
    );
    test(
      'marks a Watch Next Episode as watched and refreshes supplementary sections',
      () async {
        final _FakeShowsRepository repository = _FakeShowsRepository(
          watchNext: <WatchNextShow>[_watchNextShow()],
          staleWatching: <StaleWatchingShow>[_staleWatchingShow()],
        );

        final ShowsCubit cubit = ShowsCubit(repository: repository);

        await cubit.load();

        expect(repository.watchNextCalls, 1);
        expect(repository.staleWatchingCalls, 1);

        await cubit.markWatchNextEpisodeWatched(episodeId: 'episode-uuid');

        expect(repository.markEpisodeWatchedCalls, 1);
        expect(repository.markedEpisodeIds, <String>['episode-uuid']);

        expect(
          repository.watchNextCalls,
          2,
          reason: 'Watch Next must be refreshed after changing progress.',
        );

        expect(
          repository.staleWatchingCalls,
          2,
          reason: 'Stale Watching may also change after watching an Episode.',
        );

        expect(cubit.state.updatingWatchNextEpisodeId, isNull);
        expect(cubit.state.watchNextOperationError, isNull);

        await cubit.close();
      },
    );
    test(
      'preserves Watch Next when marking an Episode as watched fails',
      () async {
        const AppException expectedError = AppException.connection();

        final _FakeShowsRepository repository = _FakeShowsRepository(
          watchNext: <WatchNextShow>[_watchNextShow()],
          markEpisodeWatchedError: expectedError,
        );

        final ShowsCubit cubit = ShowsCubit(repository: repository);

        await cubit.load();

        final List<WatchNextShow> watchNextBeforeOperation =
            cubit.state.watchNext;

        await cubit.markWatchNextEpisodeWatched(episodeId: 'episode-uuid');

        expect(repository.markEpisodeWatchedCalls, 1);

        expect(
          repository.watchNextCalls,
          1,
          reason: 'A failed mutation must not trigger a Watch Next refresh.',
        );

        expect(
          repository.staleWatchingCalls,
          1,
          reason: 'A failed mutation must not refresh stale Watching.',
        );

        expect(cubit.state.watchNext, watchNextBeforeOperation);
        expect(cubit.state.updatingWatchNextEpisodeId, isNull);
        expect(cubit.state.watchNextOperationError, expectedError);

        await cubit.close();
      },
    );
    test(
      'maps unexpected Watch Next Episode operation errors to unknown',
      () async {
        final _FakeShowsRepository repository = _FakeShowsRepository(
          watchNext: <WatchNextShow>[_watchNextShow()],
          markEpisodeWatchedUnexpectedError: StateError('boom'),
        );

        final ShowsCubit cubit = ShowsCubit(repository: repository);

        await cubit.load();

        await cubit.markWatchNextEpisodeWatched(episodeId: 'episode-uuid');

        expect(repository.markEpisodeWatchedCalls, 1);
        expect(
          cubit.state.watchNextOperationError?.type,
          AppExceptionType.unknown,
        );
        expect(cubit.state.updatingWatchNextEpisodeId, isNull);

        await cubit.close();
      },
    );
    test(
      'updates Watch Next immediately after marking the current Episode as watched',
      () async {
        final _ChangingWatchNextRepository repository =
            _ChangingWatchNextRepository();

        final ShowsCubit cubit = ShowsCubit(repository: repository);

        await cubit.load();

        expect(repository.watchNextCalls, 1);

        expect(cubit.state.watchNext, hasLength(1));

        expect(cubit.state.watchNext.single.nextEpisode.id, 'episode-uuid');

        expect(cubit.state.watchNext.single.nextEpisode.code, 'S02E04');

        expect(cubit.state.watchNext.single.progress.watchedEpisodes, 7);

        await cubit.markWatchNextEpisodeWatched(episodeId: 'episode-uuid');

        expect(repository.markEpisodeWatchedCalls, 1);

        expect(repository.markedEpisodeIds, <String>['episode-uuid']);

        expect(
          repository.watchNextCalls,
          2,
          reason:
              'Watch Next must be reloaded after marking an Episode watched.',
        );

        expect(cubit.state.watchNext, hasLength(1));

        final WatchNextShow updated = cubit.state.watchNext.single;

        expect(updated.nextEpisode.id, 'episode-next-uuid');

        expect(updated.nextEpisode.code, 'S02E05');

        expect(updated.nextEpisode.title, 'Trojan\'s Horse');

        expect(updated.progress.watchedEpisodes, 8);

        expect(updated.progress.airedEpisodes, 10);

        expect(updated.progress.percentage, 80);

        expect(cubit.state.updatingWatchNextEpisodeId, isNull);

        expect(cubit.state.watchNextOperationError, isNull);

        await cubit.close();
      },
    );
    test(
      'removes a Show from Watch Next when no Episode remains after marking watched',
      () async {
        final _CompletedWatchNextRepository repository =
            _CompletedWatchNextRepository();

        final ShowsCubit cubit = ShowsCubit(repository: repository);

        await cubit.load();

        expect(cubit.state.watchNext, hasLength(1));
        expect(cubit.state.watchNext.single.nextEpisode.id, 'episode-uuid');

        await cubit.markWatchNextEpisodeWatched(episodeId: 'episode-uuid');

        expect(repository.markEpisodeWatchedCalls, 1);

        expect(
          repository.watchNextCalls,
          2,
          reason: 'Watch Next must be refreshed after marking watched.',
        );

        expect(
          cubit.state.watchNext,
          isEmpty,
          reason:
              'A Show with no remaining aired unwatched Episode '
              'must leave Watch Next.',
        );

        expect(cubit.state.updatingWatchNextEpisodeId, isNull);
        expect(cubit.state.watchNextOperationError, isNull);

        await cubit.close();
      },
    );

    test(
      'starts a Planning Show and refreshes Library and supplementary sections',
      () async {
        final _FakeShowsRepository repository = _FakeShowsRepository(
          shows: <LibraryShow>[
            _libraryShow(
              tmdbId: 1396,
              title: 'Breaking Bad',
              status: LibraryStatus.planning,
            ),
          ],
          watchNext: <WatchNextShow>[_watchNextShow()],
          staleWatching: <StaleWatchingShow>[_staleWatchingShow()],
        );

        final ShowsCubit cubit = ShowsCubit(repository: repository);

        await cubit.load();

        expect(repository.libraryCalls, 1);
        expect(repository.watchNextCalls, 1);
        expect(repository.staleWatchingCalls, 1);

        await cubit.startShow(showId: 'show-1396');

        expect(repository.startShowCalls, 1);
        expect(repository.startedShowIds, <String>['show-1396']);

        expect(
          repository.libraryCalls,
          2,
          reason: 'Library status must be refreshed after starting a Show.',
        );

        expect(
          repository.watchNextCalls,
          2,
          reason: 'Starting a Show may create a new Watch Next item.',
        );

        expect(
          repository.staleWatchingCalls,
          2,
          reason: 'Supplementary Watching state must remain server-driven.',
        );

        expect(cubit.state.startingShowId, isNull);
        expect(cubit.state.startShowError, isNull);

        await cubit.close();
      },
    );

    test('preserves existing Shows when starting a Show fails', () async {
      const AppException expectedError = AppException.connection();

      final _FakeShowsRepository repository = _FakeShowsRepository(
        shows: <LibraryShow>[
          _libraryShow(
            tmdbId: 1396,
            title: 'Breaking Bad',
            status: LibraryStatus.planning,
          ),
        ],
        startShowError: expectedError,
      );

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      await cubit.load();

      final List<LibraryShow> libraryBeforeOperation = cubit.state.libraryShows;

      await cubit.startShow(showId: 'show-1396');

      expect(repository.startShowCalls, 1);

      expect(
        repository.libraryCalls,
        1,
        reason: 'A failed mutation must not refresh Library.',
      );

      expect(cubit.state.libraryShows, libraryBeforeOperation);
      expect(cubit.state.startingShowId, isNull);
      expect(cubit.state.startShowError, expectedError);

      await cubit.close();
    });

    test('maps unexpected Start Show errors to unknown', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        startShowUnexpectedError: StateError('boom'),
      );

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      await cubit.startShow(showId: 'show-1396');

      expect(repository.startShowCalls, 1);
      expect(cubit.state.startShowError?.type, AppExceptionType.unknown);
      expect(cubit.state.startingShowId, isNull);

      await cubit.close();
    });
  });
}

LibraryShow _libraryShow({
  required int tmdbId,
  required String title,
  required LibraryStatus status,
}) {
  return LibraryShow(
    libraryEntryId: 'library-$tmdbId',
    showId: 'show-$tmdbId',
    tmdbId: tmdbId,
    title: title,
    originalTitle: title,
    status: status,
    showStatus: 'Returning Series',
    voteAverage: 8.0,
    createdAt: DateTime.utc(2026, 8, 1),
    updatedAt: DateTime.utc(2026, 8, 10),
  );
}

WatchNextShow _watchNextShow() {
  return WatchNextShow(
    libraryEntryId: 'library-95396',
    libraryStatus: LibraryStatus.watching,
    showId: 'show-95396',
    showTmdbId: 95396,
    showTitle: 'Severance',
    posterUrl: null,
    backdropUrl: null,
    nextEpisode: WatchNextEpisode(
      id: 'episode-uuid',
      tmdbId: 1947648,
      seasonNumber: 2,
      episodeNumber: 4,
      title: "Woe's Hollow",
      airDate: DateTime(2026, 8, 10),
      runtime: 52,
      stillUrl: null,
    ),
    progress: const WatchNextProgress(
      watchedEpisodes: 7,
      airedEpisodes: 10,
      percentage: 70,
    ),
  );
}

WatchHistoryItem _watchHistoryItem({
  required String episodeId,
  required int episodeNumber,
  required String title,
}) {
  return WatchHistoryItem(
    showId: 'show-95396',
    showTmdbId: 95396,
    showTitle: 'Severance',
    eventId: 'watch-event-1',
    posterUrl: null,
    backdropUrl: null,
    episode: WatchHistoryEpisode(
      id: episodeId,
      tmdbId: 1900000 + episodeNumber,
      seasonNumber: 2,
      episodeNumber: episodeNumber,
      watchCount: 1,
      title: title,
      watchedAt: DateTime.utc(2026, 8, 13, 20),
      airDate: DateTime.utc(2026, 8, 10),
      runtime: 52,
      stillUrl: null,
    ),
  );
}

StaleWatchingShow _staleWatchingShow() {
  return StaleWatchingShow(
    libraryEntryId: 'library-95396',
    libraryStatus: LibraryStatus.watching,
    showId: 'show-95396',
    showTmdbId: 95396,
    showTitle: 'Severance',
    posterUrl: null,
    backdropUrl: null,
    lastWatched: StaleWatchingEpisode(
      id: 'episode-last-uuid',
      tmdbId: 1947647,
      seasonNumber: 2,
      episodeNumber: 3,
      title: 'Who Is Alive?',
      watchedAt: DateTime.utc(2026, 5, 1, 20),
      airDate: DateTime(2026, 5, 1),
      runtime: 50,
      stillUrl: null,
    ),
    nextEpisode: WatchNextEpisode(
      id: 'episode-next-uuid',
      tmdbId: 1947648,
      seasonNumber: 2,
      episodeNumber: 4,
      title: "Woe's Hollow",
      airDate: DateTime(2026, 5, 8),
      runtime: 52,
      stillUrl: null,
    ),
  );
}

final class _FakeShowsRepository implements ShowsRepository {
  _FakeShowsRepository({
    this.shows = const <LibraryShow>[],
    this.watchNext = const <WatchNextShow>[],
    this.staleWatching = const <StaleWatchingShow>[],
    this.libraryError,
    this.libraryUnexpectedError,
    this.watchNextError,
    this.watchNextUnexpectedError,
    this.staleWatchingError,
    this.staleWatchingUnexpectedError,
    this.watchHistoryPages = const <WatchHistoryPage>[],
    this.watchHistoryErrors = const <AppException?>[],
    this.watchHistoryUnexpectedErrors = const <Object?>[],
    this.markEpisodeWatchedError,
    this.markEpisodeWatchedUnexpectedError,
    this.startShowError,
    this.startShowUnexpectedError,
  });

  final List<LibraryShow> shows;
  final List<WatchNextShow> watchNext;
  final List<StaleWatchingShow> staleWatching;

  final AppException? libraryError;
  final Object? libraryUnexpectedError;

  final AppException? watchNextError;
  final Object? watchNextUnexpectedError;

  final AppException? staleWatchingError;
  final Object? staleWatchingUnexpectedError;

  final List<WatchHistoryPage> watchHistoryPages;
  final List<AppException?> watchHistoryErrors;
  final List<Object?> watchHistoryUnexpectedErrors;
  final AppException? markEpisodeWatchedError;
  final Object? markEpisodeWatchedUnexpectedError;

  int markEpisodeWatchedCalls = 0;
  final List<String> markedEpisodeIds = <String>[];

  int watchHistoryCalls = 0;

  final List<String?> watchHistoryCursors = <String?>[];

  int libraryCalls = 0;
  int watchNextCalls = 0;
  int staleWatchingCalls = 0;

  int startShowCalls = 0;
  final List<String> startedShowIds = <String>[];

  final AppException? startShowError;
  final Object? startShowUnexpectedError;

  @override
  Future<List<LibraryShow>> getLibraryShows() async {
    libraryCalls++;

    final AppException? appError = libraryError;

    if (appError != null) {
      throw appError;
    }

    final Object? unknownError = libraryUnexpectedError;

    if (unknownError != null) {
      throw unknownError;
    }

    return shows;
  }

  @override
  Future<List<WatchNextShow>> getWatchNext() async {
    watchNextCalls++;

    final AppException? appError = watchNextError;

    if (appError != null) {
      throw appError;
    }

    final Object? unknownError = watchNextUnexpectedError;

    if (unknownError != null) {
      throw unknownError;
    }

    return watchNext;
  }

  @override
  Future<List<StaleWatchingShow>> getStaleWatching() async {
    staleWatchingCalls++;

    final AppException? appError = staleWatchingError;

    if (appError != null) {
      throw appError;
    }

    final Object? unknownError = staleWatchingUnexpectedError;

    if (unknownError != null) {
      throw unknownError;
    }

    return staleWatching;
  }

  @override
  Future<void> startShow({required String showId}) async {
    startShowCalls++;
    startedShowIds.add(showId);

    final AppException? appError = startShowError;

    if (appError != null) {
      throw appError;
    }

    final Object? unknownError = startShowUnexpectedError;

    if (unknownError != null) {
      throw unknownError;
    }
  }

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) async {}

  @override
  Future<void> markEpisodeWatched({required String episodeId}) async {
    markEpisodeWatchedCalls++;
    markedEpisodeIds.add(episodeId);

    final AppException? appError = markEpisodeWatchedError;

    if (appError != null) {
      throw appError;
    }

    final Object? unknownError = markEpisodeWatchedUnexpectedError;

    if (unknownError != null) {
      throw unknownError;
    }
  }

  @override
  Future<WatchHistoryPage> getWatchHistory({
    int limit = 30,
    String? cursor,
  }) async {
    final int callIndex = watchHistoryCalls;

    watchHistoryCalls++;
    watchHistoryCursors.add(cursor);

    if (callIndex < watchHistoryErrors.length) {
      final AppException? error = watchHistoryErrors[callIndex];

      if (error != null) {
        throw error;
      }
    }

    if (callIndex < watchHistoryUnexpectedErrors.length) {
      final Object? error = watchHistoryUnexpectedErrors[callIndex];

      if (error != null) {
        throw error;
      }
    }

    if (callIndex < watchHistoryPages.length) {
      return watchHistoryPages[callIndex];
    }

    return const WatchHistoryPage(
      items: <WatchHistoryItem>[],
      nextCursor: null,
      hasMore: false,
    );
  }
}

final class _PendingWatchHistoryRepository implements ShowsRepository {
  final Completer<WatchHistoryPage> _completer = Completer<WatchHistoryPage>();

  int watchHistoryCalls = 0;

  void complete(WatchHistoryPage page) {
    _completer.complete(page);
  }

  @override
  Future<WatchHistoryPage> getWatchHistory({int limit = 30, String? cursor}) {
    watchHistoryCalls++;

    return _completer.future;
  }

  @override
  Future<List<LibraryShow>> getLibraryShows() async {
    return const <LibraryShow>[];
  }

  @override
  Future<List<StaleWatchingShow>> getStaleWatching() async {
    return const <StaleWatchingShow>[];
  }

  @override
  Future<List<WatchNextShow>> getWatchNext() async {
    return const <WatchNextShow>[];
  }

  @override
  Future<void> startShow({required String showId}) async {}

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) async {}

  @override
  Future<void> markEpisodeWatched({required String episodeId}) async {}
}

final class _PendingLoadMoreWatchHistoryRepository implements ShowsRepository {
  final Completer<WatchHistoryPage> _loadMoreCompleter =
      Completer<WatchHistoryPage>();

  int watchHistoryCalls = 0;

  void completeLoadMore(WatchHistoryPage page) {
    _loadMoreCompleter.complete(page);
  }

  @override
  Future<WatchHistoryPage> getWatchHistory({int limit = 30, String? cursor}) {
    watchHistoryCalls++;

    if (cursor == null) {
      return Future<WatchHistoryPage>.value(
        WatchHistoryPage(
          items: <WatchHistoryItem>[
            _watchHistoryItem(
              episodeId: 'episode-1',
              episodeNumber: 4,
              title: "Woe's Hollow",
            ),
          ],
          nextCursor: 'cursor-1',
          hasMore: true,
        ),
      );
    }

    expect(cursor, 'cursor-1');

    return _loadMoreCompleter.future;
  }

  @override
  Future<List<LibraryShow>> getLibraryShows() async {
    return const <LibraryShow>[];
  }

  @override
  Future<List<StaleWatchingShow>> getStaleWatching() async {
    return const <StaleWatchingShow>[];
  }

  @override
  Future<List<WatchNextShow>> getWatchNext() async {
    return const <WatchNextShow>[];
  }

  @override
  Future<void> startShow({required String showId}) async {}

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) async {}

  @override
  Future<void> markEpisodeWatched({required String episodeId}) async {}
}

final class _ChangingWatchNextRepository implements ShowsRepository {
  int watchNextCalls = 0;
  int staleWatchingCalls = 0;
  int markEpisodeWatchedCalls = 0;

  final List<String> markedEpisodeIds = <String>[];

  @override
  Future<List<LibraryShow>> getLibraryShows() async {
    return <LibraryShow>[
      _libraryShow(
        tmdbId: 95396,
        title: 'Severance',
        status: LibraryStatus.watching,
      ),
    ];
  }

  @override
  Future<List<WatchNextShow>> getWatchNext() async {
    watchNextCalls++;

    if (watchNextCalls == 1) {
      return <WatchNextShow>[_watchNextShow()];
    }

    return <WatchNextShow>[
      WatchNextShow(
        libraryEntryId: 'library-95396',
        libraryStatus: LibraryStatus.watching,
        showId: 'show-95396',
        showTmdbId: 95396,
        showTitle: 'Severance',
        posterUrl: null,
        backdropUrl: null,
        nextEpisode: WatchNextEpisode(
          id: 'episode-next-uuid',
          tmdbId: 1947649,
          seasonNumber: 2,
          episodeNumber: 5,
          title: 'Trojan\'s Horse',
          airDate: DateTime(2026, 8, 11),
          runtime: 51,
          stillUrl: null,
        ),
        progress: const WatchNextProgress(
          watchedEpisodes: 8,
          airedEpisodes: 10,
          percentage: 80,
        ),
      ),
    ];
  }

  @override
  Future<List<StaleWatchingShow>> getStaleWatching() async {
    staleWatchingCalls++;

    return const <StaleWatchingShow>[];
  }

  @override
  Future<WatchHistoryPage> getWatchHistory({
    int limit = 30,
    String? cursor,
  }) async {
    return const WatchHistoryPage(
      items: <WatchHistoryItem>[],
      nextCursor: null,
      hasMore: false,
    );
  }

  @override
  Future<void> markEpisodeWatched({required String episodeId}) async {
    markEpisodeWatchedCalls++;
    markedEpisodeIds.add(episodeId);
  }

  @override
  Future<void> startShow({required String showId}) async {}

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) async {}
}

final class _CompletedWatchNextRepository implements ShowsRepository {
  int watchNextCalls = 0;
  int markEpisodeWatchedCalls = 0;

  @override
  Future<List<LibraryShow>> getLibraryShows() async {
    return <LibraryShow>[
      _libraryShow(
        tmdbId: 95396,
        title: 'Severance',
        status: LibraryStatus.watching,
      ),
    ];
  }

  @override
  Future<List<WatchNextShow>> getWatchNext() async {
    watchNextCalls++;

    if (watchNextCalls == 1) {
      return <WatchNextShow>[_watchNextShow()];
    }

    return const <WatchNextShow>[];
  }

  @override
  Future<List<StaleWatchingShow>> getStaleWatching() async {
    return const <StaleWatchingShow>[];
  }

  @override
  Future<WatchHistoryPage> getWatchHistory({
    int limit = 30,
    String? cursor,
  }) async {
    return const WatchHistoryPage(
      items: <WatchHistoryItem>[],
      nextCursor: null,
      hasMore: false,
    );
  }

  @override
  Future<void> markEpisodeWatched({required String episodeId}) async {
    markEpisodeWatchedCalls++;
  }

  @override
  Future<void> startShow({required String showId}) async {}

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) async {}
}
