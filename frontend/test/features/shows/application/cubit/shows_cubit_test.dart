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
import 'package:sofawatch/features/shows/domain/models/upcoming_episode.dart';
import 'package:sofawatch/features/shows/domain/models/upcoming_item.dart';

void main() {
  group('ShowsCubit', () {
    test('starts with an empty Shows state', () {
      final ShowsCubit cubit = ShowsCubit(repository: _FakeShowsRepository());

      expect(cubit.state, const ShowsState());
      expect(cubit.state.hasLoadedUpcoming, isFalse);
      expect(cubit.state.upcomingFromDate, isNull);
      expect(cubit.state.upcomingToDate, isNull);
      expect(cubit.state.isLoadingEarlierUpcoming, isFalse);
      expect(cubit.state.earlierUpcomingError, isNull);

      cubit.close();
    });

    test('loads Library and supplementary Shows collections', () async {
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
        upcoming: <UpcomingItem>[_upcomingItem()],
      );

      final ShowsCubit cubit = ShowsCubit(
        repository: repository,
        now: () => DateTime(2026, 8, 15, 12, 30),
      );

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

      expect(repository.upcomingCalls, 1);
      expect(repository.upcomingFromDates, <DateTime?>[DateTime(2026, 8, 8)]);

      expect(repository.upcomingToDates, <DateTime?>[null]);

      expect(cubit.state.upcomingFromDate, DateTime(2026, 8, 8));

      expect(cubit.state.upcomingToDate, isNull);
      expect(cubit.state.hasLoadedUpcoming, isTrue);

      expect(cubit.state.upcoming, repository.upcoming);

      expect(cubit.state.upcomingError, isNull);
      expect(cubit.state.isLoadingUpcoming, isFalse);

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

      expect(cubit.state.upcoming, isEmpty);
      expect(cubit.state.isUpcomingEmpty, isTrue);

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
        expect(repository.upcomingCalls, 0);

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
        upcoming: <UpcomingItem>[_upcomingItem()],
      );

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      await cubit.load();

      expect(repository.libraryCalls, 1);
      expect(repository.watchNextCalls, 1);
      expect(repository.staleWatchingCalls, 1);
      expect(repository.upcomingCalls, 1);

      await cubit.retry();

      expect(repository.libraryCalls, 2);
      expect(repository.watchNextCalls, 2);
      expect(repository.staleWatchingCalls, 2);
      expect(repository.upcomingCalls, 2);

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
      'rewatches a Watch History Episode and refreshes affected collections',
      () async {
        final _FakeShowsRepository repository = _FakeShowsRepository(
          watchHistoryPages: <WatchHistoryPage>[
            WatchHistoryPage(
              items: <WatchHistoryItem>[
                _watchHistoryItem(
                  eventId: 'watch-event-old',
                  episodeId: 'episode-1',
                  episodeNumber: 4,
                  title: "Woe's Hollow",
                ),
              ],
              nextCursor: null,
              hasMore: false,
            ),
            WatchHistoryPage(
              items: <WatchHistoryItem>[
                _watchHistoryItem(
                  eventId: 'watch-event-new',
                  episodeId: 'episode-1',
                  episodeNumber: 4,
                  title: "Woe's Hollow",
                ),
                _watchHistoryItem(
                  eventId: 'watch-event-old',
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
        expect(cubit.state.watchHistory, hasLength(1));
        expect(cubit.state.watchHistory.single.eventId, 'watch-event-old');

        await cubit.rewatchWatchHistoryEpisode(
          eventId: 'watch-event-old',
          episodeId: 'episode-1',
        );

        expect(repository.markEpisodeWatchedCalls, 1);
        expect(repository.markedEpisodeIds, <String>['episode-1']);

        expect(
          repository.watchHistoryCalls,
          2,
          reason: 'Rewatch must reload Watch History from the backend.',
        );

        expect(
          repository.watchNextCalls,
          1,
          reason: 'Rewatch may affect Watch Next.',
        );

        expect(
          repository.staleWatchingCalls,
          1,
          reason: 'Rewatch may affect stale Watching.',
        );

        expect(cubit.state.watchHistory, hasLength(2));

        expect(
          cubit.state.watchHistory
              .map((WatchHistoryItem item) => item.eventId)
              .toList(),
          <String>['watch-event-new', 'watch-event-old'],
        );

        expect(
          cubit.state.watchHistory
              .map((WatchHistoryItem item) => item.episode.id)
              .toSet(),
          <String>{'episode-1'},
          reason:
              'A rewatch creates another viewing event for the same Episode.',
        );

        expect(cubit.state.updatingWatchHistoryEventId, isNull);
        expect(cubit.state.watchHistoryOperationError, isNull);

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
        expect(
          repository.upcomingCalls,
          2,
          reason: 'Starting a Show may change the Upcoming timeline.',
        );

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
    test('preserves existing Shows data when Upcoming fails', () async {
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
        staleWatching: <StaleWatchingShow>[_staleWatchingShow()],
        upcomingError: expectedError,
      );

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      await cubit.load();

      expect(cubit.state.error, isNull);

      expect(cubit.state.libraryShows, hasLength(1));
      expect(cubit.state.watchNext, hasLength(1));
      expect(cubit.state.staleWatching, hasLength(1));

      expect(cubit.state.upcoming, isEmpty);
      expect(cubit.state.upcomingError, expectedError);
      expect(cubit.state.isLoadingUpcoming, isFalse);

      await cubit.close();
    });

    test('maps unexpected Upcoming errors without failing the page', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        shows: <LibraryShow>[
          _libraryShow(
            tmdbId: 95396,
            title: 'Severance',
            status: LibraryStatus.watching,
          ),
        ],
        upcomingUnexpectedError: StateError('boom'),
      );

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      await cubit.load();

      expect(cubit.state.error, isNull);

      expect(cubit.state.upcomingError?.type, AppExceptionType.unknown);

      expect(cubit.state.libraryShows, hasLength(1));
      expect(cubit.state.isLoadingUpcoming, isFalse);

      await cubit.close();
    });
    test('retryUpcoming reloads only Upcoming', () async {
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
        upcoming: <UpcomingItem>[_upcomingItem()],
      );

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      await cubit.load();

      expect(repository.libraryCalls, 1);
      expect(repository.watchNextCalls, 1);
      expect(repository.staleWatchingCalls, 1);
      expect(repository.upcomingCalls, 1);

      await cubit.retryUpcoming();

      expect(repository.libraryCalls, 1);
      expect(repository.watchNextCalls, 1);
      expect(repository.staleWatchingCalls, 1);
      expect(repository.upcomingCalls, 2);

      await cubit.close();
    });
    test(
      'loads Upcoming from seven days before Today without a future limit',
      () async {
        final _FakeShowsRepository repository = _FakeShowsRepository(
          upcoming: <UpcomingItem>[_upcomingItem()],
        );

        final ShowsCubit cubit = ShowsCubit(
          repository: repository,
          now: () => DateTime(2026, 8, 15, 23, 59, 45),
        );

        await cubit.load();

        expect(repository.upcomingCalls, 1);

        expect(repository.upcomingFromDates.single, DateTime(2026, 8, 8));

        expect(repository.upcomingToDates.single, isNull);

        expect(cubit.state.upcomingFromDate, DateTime(2026, 8, 8));

        expect(cubit.state.upcomingToDate, isNull);
        expect(cubit.state.hasLoadedUpcoming, isTrue);

        await cubit.close();
      },
    );
    test(
      'retryUpcoming retries the initial seven-day window after failure',
      () async {
        final _RetryInitialUpcomingRepository repository =
            _RetryInitialUpcomingRepository();

        final ShowsCubit cubit = ShowsCubit(
          repository: repository,
          now: () => DateTime(2026, 8, 15, 12),
        );

        await cubit.load();

        expect(repository.upcomingCalls, 1);
        expect(cubit.state.hasLoadedUpcoming, isFalse);
        expect(cubit.state.upcomingError, isNotNull);

        await cubit.retryUpcoming();

        expect(repository.upcomingCalls, 2);

        expect(repository.fromDates, <DateTime?>[
          DateTime(2026, 8, 8),
          DateTime(2026, 8, 8),
        ]);

        expect(repository.toDates, <DateTime?>[null, null]);

        expect(cubit.state.hasLoadedUpcoming, isTrue);
        expect(cubit.state.upcomingError, isNull);
        expect(cubit.state.upcomingFromDate, DateTime(2026, 8, 8));

        await cubit.close();
      },
    );
    test(
      'loads earlier Upcoming items and prepends them chronologically',
      () async {
        final _EarlierUpcomingRepository repository =
            _EarlierUpcomingRepository();

        final ShowsCubit cubit = ShowsCubit(
          repository: repository,
          now: () => DateTime(2026, 8, 15, 12),
        );

        await cubit.load();

        expect(cubit.state.upcomingFromDate, DateTime(2026, 8, 8));

        expect(
          cubit.state.upcoming.map((UpcomingItem item) => item.episode.id),
          <String>['current-episode'],
        );

        await cubit.loadEarlierUpcoming();

        expect(repository.upcomingCalls, 2);

        expect(repository.fromDates, <DateTime?>[
          DateTime(2026, 8, 8),
          DateTime(2026, 7, 25),
        ]);

        expect(repository.toDates, <DateTime?>[null, DateTime(2026, 8, 7)]);

        expect(
          cubit.state.upcoming.map((UpcomingItem item) => item.episode.id),
          <String>['earlier-episode', 'current-episode'],
        );

        expect(cubit.state.upcomingFromDate, DateTime(2026, 7, 25));

        expect(cubit.state.upcomingToDate, isNull);
        expect(cubit.state.isLoadingEarlierUpcoming, isFalse);
        expect(cubit.state.earlierUpcomingError, isNull);

        await cubit.close();
      },
    );
    test(
      'does not duplicate Upcoming Episodes when earlier range overlaps',
      () async {
        final _OverlappingEarlierUpcomingRepository repository =
            _OverlappingEarlierUpcomingRepository();

        final ShowsCubit cubit = ShowsCubit(
          repository: repository,
          now: () => DateTime(2026, 8, 15, 12),
        );

        await cubit.load();
        await cubit.loadEarlierUpcoming();

        expect(
          cubit.state.upcoming
              .map((UpcomingItem item) => item.episode.id)
              .toList(),
          <String>['earlier-episode', 'current-episode'],
        );

        await cubit.close();
      },
    );
    test(
      'preserves Upcoming timeline when loading earlier items fails',
      () async {
        const AppException expectedError = AppException.connection();

        final _FailingEarlierUpcomingRepository repository =
            _FailingEarlierUpcomingRepository();

        final ShowsCubit cubit = ShowsCubit(
          repository: repository,
          now: () => DateTime(2026, 8, 15, 12),
        );

        await cubit.load();

        final List<UpcomingItem> before = cubit.state.upcoming;
        final DateTime? fromDateBefore = cubit.state.upcomingFromDate;

        await cubit.loadEarlierUpcoming();

        expect(cubit.state.upcoming, before);

        expect(
          cubit.state.upcomingFromDate,
          fromDateBefore,
          reason:
              'A failed historical request must not advance the loaded range.',
        );

        expect(cubit.state.earlierUpcomingError, expectedError);
        expect(cubit.state.isLoadingEarlierUpcoming, isFalse);

        await cubit.close();
      },
    );
    test('preserves loaded Upcoming range when starting a Show', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        shows: <LibraryShow>[
          _libraryShow(
            tmdbId: 1396,
            title: 'Breaking Bad',
            status: LibraryStatus.planning,
          ),
        ],
        upcoming: <UpcomingItem>[_upcomingItem()],
      );

      final ShowsCubit cubit = ShowsCubit(
        repository: repository,
        now: () => DateTime(2026, 8, 15, 12),
      );

      await cubit.load();

      expect(cubit.state.upcomingFromDate, DateTime(2026, 8, 8));

      await cubit.loadEarlierUpcoming();

      expect(cubit.state.upcomingFromDate, DateTime(2026, 7, 25));

      expect(repository.upcomingCalls, 2);

      await cubit.startShow(showId: 'show-1396');

      expect(repository.startShowCalls, 1);

      expect(repository.upcomingCalls, 3);

      expect(
        repository.upcomingFromDates.last,
        DateTime(2026, 7, 25),
        reason:
            'Refreshing Upcoming after starting a Show must preserve '
            'the historical range already loaded.',
      );

      expect(repository.upcomingToDates.last, isNull);

      expect(cubit.state.upcomingFromDate, DateTime(2026, 7, 25));

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
  String eventId = 'watch-event-1',
}) {
  return WatchHistoryItem(
    showId: 'show-95396',
    showTmdbId: 95396,
    showTitle: 'Severance',
    eventId: eventId,
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

UpcomingItem _upcomingItem({
  String libraryEntryId = 'library-95396',
  LibraryStatus libraryStatus = LibraryStatus.watching,
  String showId = 'show-95396',
  int showTmdbId = 95396,
  String showTitle = 'Severance',
  String episodeId = 'upcoming-episode-uuid',
  int episodeTmdbId = 2000001,
  int seasonNumber = 3,
  int episodeNumber = 1,
  String episodeTitle = 'Upcoming Episode',
  DateTime? airDate,
}) {
  return UpcomingItem(
    libraryEntryId: libraryEntryId,
    libraryStatus: libraryStatus,
    showId: showId,
    showTmdbId: showTmdbId,
    showTitle: showTitle,
    posterUrl: null,
    backdropUrl: null,
    episode: UpcomingEpisode(
      id: episodeId,
      tmdbId: episodeTmdbId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      title: episodeTitle,
      airDate: airDate ?? DateTime(2026, 8, 20),
      runtime: 52,
      stillUrl: null,
    ),
  );
}

class _FakeShowsRepository implements ShowsRepository {
  _FakeShowsRepository({
    this.shows = const <LibraryShow>[],
    this.watchNext = const <WatchNextShow>[],
    this.staleWatching = const <StaleWatchingShow>[],
    this.upcoming = const <UpcomingItem>[],
    this.libraryError,
    this.libraryUnexpectedError,
    this.watchNextError,
    this.watchNextUnexpectedError,
    this.staleWatchingError,
    this.staleWatchingUnexpectedError,
    this.upcomingError,
    this.upcomingUnexpectedError,
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

  final List<UpcomingItem> upcoming;
  final AppException? upcomingError;
  final Object? upcomingUnexpectedError;

  final List<DateTime?> upcomingFromDates = <DateTime?>[];
  final List<DateTime?> upcomingToDates = <DateTime?>[];

  int _upcomingCalls = 0;

  int get upcomingCalls => _upcomingCalls;

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
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    _upcomingCalls++;

    upcomingFromDates.add(fromDate);
    upcomingToDates.add(toDate);

    final AppException? appError = upcomingError;

    if (appError != null) {
      throw appError;
    }

    final Object? unknownError = upcomingUnexpectedError;

    if (unknownError != null) {
      throw unknownError;
    }

    return upcoming;
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

  @override
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    return const <UpcomingItem>[];
  }
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

  @override
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    return const <UpcomingItem>[];
  }
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

  @override
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    return const <UpcomingItem>[];
  }
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

  @override
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    return const <UpcomingItem>[];
  }
}

final class _RetryInitialUpcomingRepository extends _FakeShowsRepository {
  int _requests = 0;

  final List<DateTime?> fromDates = <DateTime?>[];
  final List<DateTime?> toDates = <DateTime?>[];

  @override
  int get upcomingCalls => _requests;

  @override
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    _requests++;

    fromDates.add(fromDate);
    toDates.add(toDate);

    if (_requests == 1) {
      throw const AppException.connection();
    }

    return <UpcomingItem>[_upcomingItem()];
  }
}

class _EarlierUpcomingRepository extends _FakeShowsRepository {
  final List<DateTime?> fromDates = <DateTime?>[];
  final List<DateTime?> toDates = <DateTime?>[];

  @override
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    _upcomingCalls++;

    fromDates.add(fromDate);
    toDates.add(toDate);

    if (_upcomingCalls == 1) {
      return <UpcomingItem>[
        _upcomingItem(
          episodeId: 'current-episode',
          episodeTitle: 'Current Episode',
          airDate: DateTime(2026, 8, 20),
        ),
      ];
    }

    return <UpcomingItem>[
      _upcomingItem(
        episodeId: 'earlier-episode',
        episodeTmdbId: 2000002,
        episodeTitle: 'Earlier Episode',
        airDate: DateTime(2026, 8, 1),
      ),
    ];
  }
}

class _OverlappingEarlierUpcomingRepository extends _FakeShowsRepository {
  @override
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    _upcomingCalls++;

    final UpcomingItem current = _upcomingItem(
      episodeId: 'current-episode',
      episodeTitle: 'Current Episode',
      airDate: DateTime(2026, 8, 20),
    );

    if (_upcomingCalls == 1) {
      return <UpcomingItem>[current];
    }

    return <UpcomingItem>[
      _upcomingItem(
        episodeId: 'earlier-episode',
        episodeTmdbId: 2000002,
        episodeTitle: 'Earlier Episode',
        airDate: DateTime(2026, 8, 1),
      ),
      current,
    ];
  }
}

class _FailingEarlierUpcomingRepository extends _FakeShowsRepository {
  @override
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    _upcomingCalls++;

    if (_upcomingCalls == 1) {
      return <UpcomingItem>[
        _upcomingItem(
          episodeId: 'current-episode',
          episodeTitle: 'Current Episode',
          airDate: DateTime(2026, 8, 20),
        ),
      ];
    }

    throw const AppException.connection();
  }
}
