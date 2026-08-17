import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/home/application/cubit/home_cubit.dart';
import 'package:sofawatch/features/home/application/cubit/home_state.dart';
import 'package:sofawatch/features/home/application/models/home_watch_source.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';
import 'package:sofawatch/features/shows/domain/models/stale_watching_show.dart';
import 'package:sofawatch/features/shows/domain/models/upcoming_episode.dart';
import 'package:sofawatch/features/shows/domain/models/upcoming_item.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_episode.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_item.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_page.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_episode.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_progress.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_show.dart';
import 'package:sofawatch/features/shows/domain/repositories/shows_repository.dart';

final DateTime _referenceToday = DateTime(2026, 8, 17);

DateTime _relativeDay(int offset) {
  return _referenceToday.add(Duration(days: offset));
}

void main() {
  group('HomeCubit Premiering Today', () {
    test('loads only today and limits Home results', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        upcoming: List<UpcomingItem>.generate(
          8,
          (int index) => _upcomingItem(
            episodeId: 'episode-$index',
            airDate: _referenceToday,
          ),
        ),
      );

      final HomeCubit cubit = HomeCubit(
        repository: repository,
        now: () => DateTime(2026, 8, 17, 14, 30),
      );

      await cubit.loadPremieringToday();

      expect(
        cubit.state.premieringToday,
        hasLength(HomeCubit.premieringTodayLimit),
      );

      expect(repository.requestedFromDate, _referenceToday);
      expect(repository.requestedToDate, _referenceToday);

      await cubit.close();
    });

    test('uses the injected current day when the date advances', () async {
      final DateTime simulatedToday = DateTime(2026, 8, 18);

      final _FakeShowsRepository repository = _FakeShowsRepository(
        upcoming: <UpcomingItem>[
          _upcomingItem(episodeId: 'episode-18', airDate: simulatedToday),
        ],
      );

      final HomeCubit cubit = HomeCubit(
        repository: repository,
        now: () => DateTime(2026, 8, 18, 9, 15),
      );

      await cubit.loadPremieringToday();

      expect(repository.requestedFromDate, simulatedToday);
      expect(repository.requestedToDate, simulatedToday);

      await cubit.close();
    });

    test('marks Premiering Today Episode as watched', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        upcoming: <UpcomingItem>[
          _upcomingItem(
            episodeId: 'episode-1',
            airDate: _referenceToday,
            isWatched: false,
          ),
        ],
      );

      final HomeCubit cubit = HomeCubit(
        repository: repository,
        now: () => _referenceToday,
      );

      await cubit.loadPremieringToday();

      expect(cubit.state.premieringToday.single.episode.isWatched, isFalse);

      await cubit.markPremieringTodayEpisodeWatched(episodeId: 'episode-1');

      expect(repository.markWatchedCalls, 1);

      expect(cubit.state.premieringToday.single.episode.isWatched, isTrue);

      expect(cubit.state.updatingEpisodeId, isNull);
      expect(cubit.state.updatingEpisodeSource, isNull);
      expect(cubit.state.watchOperationError, isNull);

      await cubit.close();
    });

    test('supports the unified public watched action', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        upcoming: <UpcomingItem>[
          _upcomingItem(
            episodeId: 'episode-1',
            airDate: _referenceToday,
            isWatched: false,
          ),
        ],
      );

      final HomeCubit cubit = HomeCubit(
        repository: repository,
        now: () => _referenceToday,
      );

      await cubit.loadPremieringToday();

      await cubit.markEpisodeWatched(
        episodeId: 'episode-1',
        source: HomeWatchSource.premieringToday,
      );

      expect(repository.markWatchedCalls, 1);

      expect(cubit.state.premieringToday.single.episode.isWatched, isTrue);

      expect(cubit.state.updatingEpisodeId, isNull);
      expect(cubit.state.updatingEpisodeSource, isNull);
      expect(cubit.state.watchOperationError, isNull);

      await cubit.close();
    });

    test('rolls back optimistic watched state when mutation fails', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        upcoming: <UpcomingItem>[
          _upcomingItem(
            episodeId: 'episode-1',
            airDate: _referenceToday,
            isWatched: false,
          ),
        ],
        failMarkWatched: true,
      );

      final HomeCubit cubit = HomeCubit(
        repository: repository,
        now: () => _referenceToday,
      );

      await cubit.loadPremieringToday();

      await cubit.markPremieringTodayEpisodeWatched(episodeId: 'episode-1');

      expect(cubit.state.premieringToday.single.episode.isWatched, isFalse);

      expect(cubit.state.updatingEpisodeId, isNull);
      expect(cubit.state.updatingEpisodeSource, isNull);
      expect(cubit.state.watchOperationError, isA<AppException>());

      await cubit.close();
    });

    test('does not record another watch for already watched Episode', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        upcoming: <UpcomingItem>[
          _upcomingItem(
            episodeId: 'episode-1',
            airDate: _referenceToday,
            isWatched: true,
          ),
        ],
      );

      final HomeCubit cubit = HomeCubit(
        repository: repository,
        now: () => _referenceToday,
      );

      await cubit.loadPremieringToday();

      await cubit.markPremieringTodayEpisodeWatched(episodeId: 'episode-1');

      expect(repository.markWatchedCalls, 0);
      expect(repository.watchHistoryCalls, 0);

      await cubit.close();
    });
  });

  group('HomeCubit Upcoming', () {
    test('loads tomorrow through the following seven days', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        upcoming: <UpcomingItem>[
          _upcomingItem(episodeId: 'episode-1', airDate: _relativeDay(1)),
        ],
      );

      final HomeCubit cubit = HomeCubit(
        repository: repository,
        now: () => DateTime(2026, 8, 17, 14, 30),
      );

      await cubit.loadUpcoming();

      expect(repository.requestedFromDate, _relativeDay(1));
      expect(repository.requestedToDate, _relativeDay(7));

      expect(cubit.state.upcoming, hasLength(1));

      await cubit.close();
    });

    test('calculates Upcoming correctly when current day advances', () async {
      final DateTime simulatedToday = DateTime(2026, 8, 18);

      final _FakeShowsRepository repository = _FakeShowsRepository(
        upcoming: <UpcomingItem>[
          _upcomingItem(
            episodeId: 'episode-19',
            airDate: DateTime(2026, 8, 19),
          ),
        ],
      );

      final HomeCubit cubit = HomeCubit(
        repository: repository,
        now: () => simulatedToday,
      );

      await cubit.loadUpcoming();

      expect(repository.requestedFromDate, DateTime(2026, 8, 19));

      expect(repository.requestedToDate, DateTime(2026, 8, 25));

      await cubit.close();
    });

    test('limits Upcoming results displayed on Home', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        upcoming: List<UpcomingItem>.generate(
          10,
          (int index) => _upcomingItem(
            episodeId: 'episode-$index',
            airDate: _relativeDay(index + 1),
          ),
        ),
      );

      final HomeCubit cubit = HomeCubit(
        repository: repository,
        now: () => _referenceToday,
      );

      await cubit.loadUpcoming();

      expect(cubit.state.upcoming, hasLength(HomeCubit.upcomingLimit));

      expect(cubit.state.upcoming.first.episode.id, 'episode-0');

      expect(cubit.state.upcoming.last.episode.id, 'episode-5');

      await cubit.close();
    });

    test('preserves Planning Shows in Upcoming', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        upcoming: <UpcomingItem>[
          _upcomingItem(
            episodeId: 'episode-planning',
            status: LibraryStatus.planning,
            airDate: _relativeDay(3),
          ),
        ],
      );

      final HomeCubit cubit = HomeCubit(
        repository: repository,
        now: () => _referenceToday,
      );

      await cubit.loadUpcoming();

      expect(cubit.state.upcoming.single.libraryStatus, LibraryStatus.planning);

      await cubit.close();
    });

    test('stores an independent Upcoming error', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        failUpcoming: true,
      );

      final HomeCubit cubit = HomeCubit(
        repository: repository,
        now: () => _referenceToday,
      );

      await cubit.loadUpcoming();

      expect(cubit.state.upcoming, isEmpty);
      expect(cubit.state.upcomingError, isA<AppException>());
      expect(cubit.state.isLoadingUpcoming, isFalse);

      await cubit.close();
    });
  });

  group('HomeCubit Missed Recently', () {
    test('loads the previous 14 days excluding today', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        upcoming: <UpcomingItem>[
          _upcomingItem(episodeId: 'episode-1', airDate: _relativeDay(-1)),
        ],
      );

      final HomeCubit cubit = HomeCubit(
        repository: repository,
        now: () => DateTime(2026, 8, 17, 14, 30),
      );

      await cubit.loadMissedRecently();

      expect(repository.requestedFromDate, _relativeDay(-14));

      expect(repository.requestedToDate, _relativeDay(-1));

      await cubit.close();
    });

    test(
      'calculates Missed Recently correctly when current day advances',
      () async {
        final DateTime simulatedToday = DateTime(2026, 8, 18);

        final _FakeShowsRepository repository = _FakeShowsRepository(
          upcoming: <UpcomingItem>[
            _upcomingItem(
              episodeId: 'episode-17',
              airDate: DateTime(2026, 8, 17),
            ),
          ],
        );

        final HomeCubit cubit = HomeCubit(
          repository: repository,
          now: () => simulatedToday,
        );

        await cubit.loadMissedRecently();

        expect(repository.requestedFromDate, DateTime(2026, 8, 4));

        expect(repository.requestedToDate, DateTime(2026, 8, 17));

        await cubit.close();
      },
    );

    test('excludes Planning Shows and watched Episodes', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        upcoming: <UpcomingItem>[
          _upcomingItem(
            episodeId: 'watching-unwatched',
            status: LibraryStatus.watching,
            isWatched: false,
            airDate: _relativeDay(-1),
          ),
          _upcomingItem(
            episodeId: 'watching-watched',
            status: LibraryStatus.watching,
            isWatched: true,
            airDate: _relativeDay(-2),
          ),
          _upcomingItem(
            episodeId: 'planning-unwatched',
            status: LibraryStatus.planning,
            isWatched: false,
            airDate: _relativeDay(-3),
          ),
        ],
      );

      final HomeCubit cubit = HomeCubit(
        repository: repository,
        now: () => _referenceToday,
      );

      await cubit.loadMissedRecently();

      expect(
        cubit.state.missedRecently.map((UpcomingItem item) => item.episode.id),
        <String>['watching-unwatched'],
      );

      await cubit.close();
    });

    test('orders missed Episodes newest first', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        upcoming: <UpcomingItem>[
          _upcomingItem(episodeId: 'oldest', airDate: _relativeDay(-12)),
          _upcomingItem(episodeId: 'newest', airDate: _relativeDay(-1)),
          _upcomingItem(episodeId: 'middle', airDate: _relativeDay(-7)),
        ],
      );

      final HomeCubit cubit = HomeCubit(
        repository: repository,
        now: () => _referenceToday,
      );

      await cubit.loadMissedRecently();

      expect(
        cubit.state.missedRecently.map((UpcomingItem item) => item.episode.id),
        <String>['newest', 'middle', 'oldest'],
      );

      await cubit.close();
    });

    test('limits Missed Recently to ten Episodes', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        upcoming: List<UpcomingItem>.generate(15, (int index) {
          final int daysAgo = 1 + (index % 14);

          return _upcomingItem(
            episodeId: 'episode-$index',
            airDate: _relativeDay(-daysAgo),
          );
        }),
      );

      final HomeCubit cubit = HomeCubit(
        repository: repository,
        now: () => _referenceToday,
      );

      await cubit.loadMissedRecently();

      expect(
        cubit.state.missedRecently,
        hasLength(HomeCubit.missedRecentlyLimit),
      );

      await cubit.close();
    });

    test('removes Episode after marking it watched', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        upcoming: <UpcomingItem>[
          _upcomingItem(episodeId: 'episode-1', airDate: _relativeDay(-1)),
          _upcomingItem(episodeId: 'episode-2', airDate: _relativeDay(-2)),
        ],
      );

      final HomeCubit cubit = HomeCubit(
        repository: repository,
        now: () => _referenceToday,
      );

      await cubit.loadMissedRecently();

      expect(cubit.state.missedRecently, hasLength(2));

      await cubit.markMissedRecentlyEpisodeWatched(episodeId: 'episode-1');

      expect(repository.markWatchedCalls, 1);

      expect(
        cubit.state.missedRecently.map((UpcomingItem item) => item.episode.id),
        <String>['episode-2'],
      );

      expect(cubit.state.updatingEpisodeId, isNull);
      expect(cubit.state.updatingEpisodeSource, isNull);
      expect(cubit.state.watchOperationError, isNull);

      await cubit.close();
    });

    test('supports unified watched action for Missed Recently', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        upcoming: <UpcomingItem>[
          _upcomingItem(episodeId: 'episode-1', airDate: _relativeDay(-1)),
        ],
      );

      final HomeCubit cubit = HomeCubit(
        repository: repository,
        now: () => _referenceToday,
      );

      await cubit.loadMissedRecently();

      await cubit.markEpisodeWatched(
        episodeId: 'episode-1',
        source: HomeWatchSource.missedRecently,
      );

      expect(repository.markWatchedCalls, 1);
      expect(cubit.state.missedRecently, isEmpty);

      await cubit.close();
    });

    test('restores Episode when marking it watched fails', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        upcoming: <UpcomingItem>[
          _upcomingItem(episodeId: 'episode-1', airDate: _relativeDay(-1)),
        ],
        failMarkWatched: true,
      );

      final HomeCubit cubit = HomeCubit(
        repository: repository,
        now: () => _referenceToday,
      );

      await cubit.loadMissedRecently();

      await cubit.markMissedRecentlyEpisodeWatched(episodeId: 'episode-1');

      expect(cubit.state.missedRecently, hasLength(1));

      expect(cubit.state.missedRecently.single.episode.id, 'episode-1');

      expect(cubit.state.updatingEpisodeId, isNull);
      expect(cubit.state.updatingEpisodeSource, isNull);
      expect(cubit.state.watchOperationError, isA<AppException>());

      await cubit.close();
    });
  });

  group('HomeCubit Recent Activity', () {
    test('loads only a small Recent Activity page', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        watchHistory: WatchHistoryPage(
          items: List<WatchHistoryItem>.generate(
            8,
            (int index) => _watchHistoryItem(
              eventId: 'event-$index',
              episodeId: 'episode-$index',
              watchedAt: DateTime.utc(2026, 8, 17, 20, index),
            ),
          ),
          hasMore: true,
          nextCursor: 'next-cursor',
        ),
      );

      final HomeCubit cubit = HomeCubit(
        repository: repository,
        now: () => _referenceToday,
      );

      await cubit.loadRecentActivity();

      expect(
        repository.requestedWatchHistoryLimit,
        HomeCubit.recentActivityLimit,
      );

      expect(
        cubit.state.recentActivity,
        hasLength(HomeCubit.recentActivityLimit),
      );

      expect(cubit.state.recentActivity.first.eventId, 'event-0');

      await cubit.close();
    });

    test('keeps Watch History order unchanged', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        watchHistory: WatchHistoryPage(
          items: <WatchHistoryItem>[
            _watchHistoryItem(
              eventId: 'newest',
              episodeId: 'episode-1',
              watchedAt: DateTime.utc(2026, 8, 17, 22),
            ),
            _watchHistoryItem(
              eventId: 'middle',
              episodeId: 'episode-2',
              watchedAt: DateTime.utc(2026, 8, 17, 20),
            ),
            _watchHistoryItem(
              eventId: 'oldest',
              episodeId: 'episode-3',
              watchedAt: DateTime.utc(2026, 8, 16, 20),
            ),
          ],
          hasMore: false,
        ),
      );

      final HomeCubit cubit = HomeCubit(
        repository: repository,
        now: () => _referenceToday,
      );

      await cubit.loadRecentActivity();

      expect(
        cubit.state.recentActivity.map((WatchHistoryItem item) => item.eventId),
        <String>['newest', 'middle', 'oldest'],
      );

      await cubit.close();
    });

    test('stores Recent Activity errors independently', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        failWatchHistory: true,
      );

      final HomeCubit cubit = HomeCubit(
        repository: repository,
        now: () => _referenceToday,
      );

      await cubit.loadRecentActivity();

      expect(cubit.state.recentActivity, isEmpty);

      expect(cubit.state.recentActivityError, isA<AppException>());

      expect(cubit.state.isLoadingRecentActivity, isFalse);

      await cubit.close();
    });
  });

  group('HomeCubit cross-section watched updates', () {
    test('marks Premiering Today watched and removes same Episode from '
        'Missed Recently', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository();

      final HomeCubit cubit = HomeCubit(
        repository: repository,
        now: () => _referenceToday,
      );

      final UpcomingItem premieringItem = _upcomingItem(
        episodeId: 'shared-episode',
        airDate: _referenceToday,
      );

      final UpcomingItem missedItem = _upcomingItem(
        episodeId: 'shared-episode',
        airDate: _relativeDay(-1),
      );

      cubit.emitForTest(
        premieringToday: <UpcomingItem>[premieringItem],
        missedRecently: <UpcomingItem>[missedItem],
      );

      await cubit.markEpisodeWatched(
        episodeId: 'shared-episode',
        source: HomeWatchSource.premieringToday,
      );

      expect(cubit.state.premieringToday.single.episode.isWatched, isTrue);

      expect(cubit.state.missedRecently, isEmpty);

      expect(repository.markWatchedCalls, 1);

      await cubit.close();
    });

    test('marking a missed Episode updates Premiering Today when the '
        'same Episode is present', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository();

      final HomeCubit cubit = HomeCubit(
        repository: repository,
        now: () => _referenceToday,
      );

      cubit.emitForTest(
        premieringToday: <UpcomingItem>[
          _upcomingItem(episodeId: 'shared-episode', airDate: _referenceToday),
        ],
        missedRecently: <UpcomingItem>[
          _upcomingItem(episodeId: 'shared-episode', airDate: _relativeDay(-1)),
        ],
      );

      await cubit.markEpisodeWatched(
        episodeId: 'shared-episode',
        source: HomeWatchSource.missedRecently,
      );

      expect(cubit.state.premieringToday.single.episode.isWatched, isTrue);

      expect(cubit.state.missedRecently, isEmpty);

      await cubit.close();
    });

    test(
      'refreshes Recent Activity after a successful watched mutation',
      () async {
        final WatchHistoryItem newActivity = _watchHistoryItem(
          eventId: 'new-event',
          episodeId: 'episode-1',
          watchedAt: DateTime.utc(2026, 8, 17, 21),
        );

        final _FakeShowsRepository repository = _FakeShowsRepository(
          watchHistory: WatchHistoryPage(
            items: <WatchHistoryItem>[newActivity],
            hasMore: false,
          ),
        );

        final HomeCubit cubit = HomeCubit(
          repository: repository,
          now: () => _referenceToday,
        );

        cubit.emitForTest(
          premieringToday: <UpcomingItem>[
            _upcomingItem(episodeId: 'episode-1', airDate: _referenceToday),
          ],
        );

        await cubit.markEpisodeWatched(
          episodeId: 'episode-1',
          source: HomeWatchSource.premieringToday,
        );

        expect(repository.markWatchedCalls, 1);

        expect(repository.watchHistoryCalls, 1);

        expect(
          repository.requestedWatchHistoryLimit,
          HomeCubit.recentActivityLimit,
        );

        expect(cubit.state.recentActivity.single.eventId, 'new-event');

        await cubit.close();
      },
    );

    test('rolls back all deterministic cross-section changes when '
        'mutation fails', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        failMarkWatched: true,
      );

      final HomeCubit cubit = HomeCubit(
        repository: repository,
        now: () => _referenceToday,
      );

      cubit.emitForTest(
        premieringToday: <UpcomingItem>[
          _upcomingItem(episodeId: 'shared-episode', airDate: _referenceToday),
        ],
        missedRecently: <UpcomingItem>[
          _upcomingItem(episodeId: 'shared-episode', airDate: _relativeDay(-1)),
        ],
      );

      await cubit.markEpisodeWatched(
        episodeId: 'shared-episode',
        source: HomeWatchSource.missedRecently,
      );

      expect(cubit.state.premieringToday.single.episode.isWatched, isFalse);

      expect(cubit.state.missedRecently, hasLength(1));

      expect(cubit.state.missedRecently.single.episode.id, 'shared-episode');

      expect(cubit.state.watchOperationError, isA<AppException>());

      /*
         * Failed writes must not fabricate/refresh server-owned
         * Watch History.
         */
      expect(repository.watchHistoryCalls, 0);

      await cubit.close();
    });

    test(
      'does not reload unrelated Upcoming data after watched mutation',
      () async {
        final _FakeShowsRepository repository = _FakeShowsRepository();

        final HomeCubit cubit = HomeCubit(
          repository: repository,
          now: () => _referenceToday,
        );

        cubit.emitForTest(
          premieringToday: <UpcomingItem>[
            _upcomingItem(episodeId: 'episode-1', airDate: _referenceToday),
          ],
        );

        await cubit.markEpisodeWatched(
          episodeId: 'episode-1',
          source: HomeWatchSource.premieringToday,
        );

        /*
       * Only the write and the small server-derived Recent Activity
       * refresh are required.
       *
       * Home must not perform a complete Upcoming reload here.
       */
        expect(repository.upcomingCalls, 0);
        expect(repository.markWatchedCalls, 1);
        expect(repository.watchHistoryCalls, 1);

        await cubit.close();
      },
    );
  });
  group('HomeCubit coordinated watch updates', () {
    test(
      'marking from Premiering Today updates affected Home sections',
      () async {
        final _FakeShowsRepository repository = _FakeShowsRepository(
          upcoming: <UpcomingItem>[
            _upcomingItem(
              episodeId: 'episode-1',
              airDate: _referenceToday,
              isWatched: false,
            ),
          ],
          watchHistory: WatchHistoryPage(
            items: <WatchHistoryItem>[
              _watchHistoryItem(
                eventId: 'event-1',
                episodeId: 'episode-1',
                watchedAt: DateTime.utc(2026, 8, 17, 20),
              ),
            ],
            hasMore: false,
          ),
        );

        final HomeCubit cubit = HomeCubit(
          repository: repository,
          now: () => _referenceToday,
        );

        await cubit.loadPremieringToday();

        expect(cubit.state.premieringToday.single.episode.isWatched, isFalse);

        await cubit.markPremieringTodayEpisodeWatched(episodeId: 'episode-1');

        expect(repository.markWatchedCalls, 1);

        expect(cubit.state.premieringToday.single.episode.isWatched, isTrue);

        expect(repository.watchHistoryCalls, 1);

        expect(cubit.state.recentActivity.single.episode.id, 'episode-1');

        expect(cubit.state.updatingEpisodeId, isNull);
        expect(cubit.state.updatingEpisodeSource, isNull);
        expect(cubit.state.watchOperationError, isNull);

        await cubit.close();
      },
    );

    test(
      'marking from Missed Recently removes Episode and refreshes Recent Activity',
      () async {
        final _FakeShowsRepository repository = _FakeShowsRepository(
          upcoming: <UpcomingItem>[
            _upcomingItem(
              episodeId: 'episode-1',
              airDate: _relativeDay(-1),
              isWatched: false,
            ),
            _upcomingItem(
              episodeId: 'episode-2',
              airDate: _relativeDay(-2),
              isWatched: false,
            ),
          ],
          watchHistory: WatchHistoryPage(
            items: <WatchHistoryItem>[
              _watchHistoryItem(
                eventId: 'event-1',
                episodeId: 'episode-1',
                watchedAt: DateTime.utc(2026, 8, 17, 20),
              ),
            ],
            hasMore: false,
          ),
        );

        final HomeCubit cubit = HomeCubit(
          repository: repository,
          now: () => _referenceToday,
        );

        await cubit.loadMissedRecently();

        expect(cubit.state.missedRecently, hasLength(2));

        await cubit.markMissedRecentlyEpisodeWatched(episodeId: 'episode-1');

        expect(repository.markWatchedCalls, 1);

        expect(
          cubit.state.missedRecently.map(
            (UpcomingItem item) => item.episode.id,
          ),
          <String>['episode-2'],
        );

        expect(repository.watchHistoryCalls, 1);

        expect(cubit.state.recentActivity.single.episode.id, 'episode-1');

        await cubit.close();
      },
    );

    test(
      'marking from Continue Watching refreshes Watch Next and Recent Activity',
      () async {
        final WatchNextShow firstWatchNext = _watchNextShow(
          episodeId: 'episode-1',
        );

        final WatchNextShow nextWatchNext = _watchNextShow(
          episodeId: 'episode-2',
        );

        final _FakeShowsRepository repository = _FakeShowsRepository(
          watchNextResponses: <List<WatchNextShow>>[
            <WatchNextShow>[firstWatchNext],
            <WatchNextShow>[nextWatchNext],
          ],
          watchHistory: WatchHistoryPage(
            items: <WatchHistoryItem>[
              _watchHistoryItem(
                eventId: 'event-1',
                episodeId: 'episode-1',
                watchedAt: DateTime.utc(2026, 8, 17, 20),
              ),
            ],
            hasMore: false,
          ),
        );

        final HomeCubit cubit = HomeCubit(
          repository: repository,
          now: () => _referenceToday,
        );

        await cubit.loadContinueWatching();

        expect(cubit.state.continueWatching.single.nextEpisode.id, 'episode-1');

        await cubit.markContinueWatchingEpisodeWatched(episodeId: 'episode-1');

        expect(repository.markWatchedCalls, 1);

        expect(repository.watchNextCalls, 2);

        expect(cubit.state.continueWatching.single.nextEpisode.id, 'episode-2');

        expect(repository.watchHistoryCalls, 1);

        await cubit.close();
      },
    );

    test(
      'marking an Episode updates matching Premiering Today and Missed Recently state',
      () async {
        final UpcomingItem todayItem = _upcomingItem(
          episodeId: 'shared-episode',
          airDate: _referenceToday,
          isWatched: false,
        );

        final UpcomingItem missedItem = _upcomingItem(
          episodeId: 'shared-episode',
          airDate: _relativeDay(-1),
          isWatched: false,
        );

        final _FakeShowsRepository repository = _FakeShowsRepository(
          watchHistory: const WatchHistoryPage(
            items: <WatchHistoryItem>[],
            hasMore: false,
          ),
        );

        final HomeCubit cubit = HomeCubit(
          repository: repository,
          now: () => _referenceToday,
        );

        cubit.emitForTest(
          premieringToday: <UpcomingItem>[todayItem],
          missedRecently: <UpcomingItem>[missedItem],
        );

        await cubit.markEpisodeWatched(
          episodeId: 'shared-episode',
          source: HomeWatchSource.premieringToday,
        );

        expect(cubit.state.premieringToday.single.episode.isWatched, isTrue);

        expect(cubit.state.missedRecently, isEmpty);

        await cubit.close();
      },
    );

    test(
      'failed coordinated watch update restores affected local sections',
      () async {
        final UpcomingItem todayItem = _upcomingItem(
          episodeId: 'episode-1',
          airDate: _referenceToday,
          isWatched: false,
        );

        final _FakeShowsRepository repository = _FakeShowsRepository(
          upcoming: <UpcomingItem>[todayItem],
          failMarkWatched: true,
        );

        final HomeCubit cubit = HomeCubit(
          repository: repository,
          now: () => _referenceToday,
        );

        await cubit.loadPremieringToday();

        await cubit.markPremieringTodayEpisodeWatched(episodeId: 'episode-1');

        expect(cubit.state.premieringToday.single.episode.isWatched, isFalse);

        expect(cubit.state.updatingEpisodeId, isNull);
        expect(cubit.state.updatingEpisodeSource, isNull);
        expect(cubit.state.watchOperationError, isA<AppException>());

        expect(repository.watchHistoryCalls, 0);

        await cubit.close();
      },
    );

    test(
      'localized watch mutation refreshes only affected server-derived collections',
      () async {
        final _FakeShowsRepository repository = _FakeShowsRepository(
          upcoming: <UpcomingItem>[
            _upcomingItem(
              episodeId: 'episode-1',
              airDate: _referenceToday,
              isWatched: false,
            ),
          ],
          watchHistory: const WatchHistoryPage(
            items: <WatchHistoryItem>[],
            hasMore: false,
          ),
        );

        final HomeCubit cubit = HomeCubit(
          repository: repository,
          now: () => _referenceToday,
        );

        await cubit.loadPremieringToday();

        final int upcomingCallsBefore = repository.upcomingCalls;
        final int watchNextCallsBefore = repository.watchNextCalls;
        final int watchHistoryCallsBefore = repository.watchHistoryCalls;

        await cubit.markPremieringTodayEpisodeWatched(episodeId: 'episode-1');

        /*
     * Premiering Today is updated locally.
     *
     * Do not reload the Upcoming timeline because the watched mutation
     * does not change future air dates.
     */
        expect(repository.upcomingCalls, upcomingCallsBefore);

        /*
     * Watch Next is server-derived and may change after watching an Episode.
     *
     * Refresh only this affected collection rather than reloading Home.
     */
        expect(repository.watchNextCalls, watchNextCallsBefore + 1);

        /*
     * Recent Activity is also server-derived because its event ID,
     * watched timestamp, watch count and ordering come from the backend.
     */
        expect(repository.watchHistoryCalls, watchHistoryCallsBefore + 1);

        expect(repository.markWatchedCalls, 1);

        await cubit.close();
      },
    );
  });
}

UpcomingItem _upcomingItem({
  required String episodeId,
  required DateTime airDate,
  bool isWatched = false,
  LibraryStatus status = LibraryStatus.watching,
}) {
  return UpcomingItem(
    libraryEntryId: 'library-$episodeId',
    libraryStatus: status,
    showId: 'show-$episodeId',
    showTmdbId: 95396,
    showTitle: 'Severance',
    posterUrl: null,
    backdropUrl: null,
    episode: UpcomingEpisode(
      id: episodeId,
      tmdbId: 1000,
      seasonNumber: 2,
      episodeNumber: 1,
      title: 'Hello, Ms. Cobel',
      airDate: airDate,
      runtime: 52,
      stillUrl: null,
      isWatched: isWatched,
    ),
  );
}

WatchHistoryItem _watchHistoryItem({
  required String eventId,
  required String episodeId,
  required DateTime watchedAt,
  int watchCount = 1,
}) {
  return WatchHistoryItem(
    eventId: eventId,
    showId: 'show-$episodeId',
    showTmdbId: 95396,
    showTitle: 'Severance',
    posterUrl: null,
    backdropUrl: null,
    episode: WatchHistoryEpisode(
      id: episodeId,
      tmdbId: 1000,
      seasonNumber: 2,
      episodeNumber: 1,
      title: 'Hello, Ms. Cobel',
      airDate: DateTime(2025, 1, 17),
      runtime: 52,
      stillUrl: null,
      watchedAt: watchedAt,
      watchCount: watchCount,
    ),
  );
}

final class _FakeShowsRepository implements ShowsRepository {
  _FakeShowsRepository({
    this.upcoming = const <UpcomingItem>[],
    this.failMarkWatched = false,
    this.failUpcoming = false,
    this.watchHistory = const WatchHistoryPage(
      items: <WatchHistoryItem>[],
      hasMore: false,
    ),
    this.failWatchHistory = false,
    this.watchNextResponses = const <List<WatchNextShow>>[],
  });

  final List<UpcomingItem> upcoming;

  final bool failMarkWatched;
  final bool failUpcoming;

  final WatchHistoryPage watchHistory;
  final bool failWatchHistory;

  DateTime? requestedFromDate;
  DateTime? requestedToDate;

  int? requestedWatchHistoryLimit;

  int upcomingCalls = 0;
  int markWatchedCalls = 0;
  int watchHistoryCalls = 0;

  int watchNextCalls = 0;

  final List<List<WatchNextShow>> watchNextResponses;

  int _watchNextResponseIndex = 0;

  @override
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    upcomingCalls++;

    requestedFromDate = fromDate;
    requestedToDate = toDate;

    if (failUpcoming) {
      throw const AppException.connection();
    }

    return upcoming;
  }

  @override
  Future<List<WatchNextShow>> getWatchNext() async {
    watchNextCalls++;

    if (watchNextResponses.isEmpty) {
      return const <WatchNextShow>[];
    }

    final int index = _watchNextResponseIndex.clamp(
      0,
      watchNextResponses.length - 1,
    );

    final List<WatchNextShow> result = watchNextResponses[index];

    if (_watchNextResponseIndex < watchNextResponses.length - 1) {
      _watchNextResponseIndex++;
    }

    return result;
  }

  @override
  Future<WatchHistoryPage> getWatchHistory({
    int limit = 30,
    String? cursor,
  }) async {
    watchHistoryCalls++;
    requestedWatchHistoryLimit = limit;

    if (failWatchHistory) {
      throw const AppException.connection();
    }

    return watchHistory;
  }

  @override
  Future<void> markEpisodeWatched({required String episodeId}) async {
    markWatchedCalls++;

    if (failMarkWatched) {
      throw const AppException.connection();
    }
  }

  @override
  Future<List<LibraryShow>> getLibraryShows() {
    throw UnimplementedError();
  }

  @override
  Future<List<StaleWatchingShow>> getStaleWatching() {
    throw UnimplementedError();
  }

  @override
  Future<void> startShow({required String showId}) {
    throw UnimplementedError();
  }

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) {
    throw UnimplementedError();
  }
}

extension _HomeCubitTestState on HomeCubit {
  void emitForTest({
    List<UpcomingItem>? premieringToday,
    List<UpcomingItem>? missedRecently,
  }) {
    emit(
      state.copyWith(
        premieringToday: premieringToday,
        missedRecently: missedRecently,
      ),
    );
  }
}

WatchNextShow _watchNextShow({
  required String episodeId,
  String showId = 'show-1',
}) {
  return WatchNextShow(
    libraryEntryId: 'library-$showId',
    libraryStatus: LibraryStatus.watching,
    showId: showId,
    showTmdbId: 95396,
    showTitle: 'Severance',
    posterUrl: null,
    backdropUrl: null,
    nextEpisode: WatchNextEpisode(
      id: episodeId,
      tmdbId: 2000,
      seasonNumber: 2,
      episodeNumber: 1,
      title: 'Episode',
      airDate: _relativeDay(-1),
      runtime: 52,
      stillUrl: null,
    ),
    progress: const WatchNextProgress(
      watchedEpisodes: 3,
      airedEpisodes: 10,
      percentage: 30,
    ),
  );
}
