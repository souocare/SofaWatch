import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/core/viewing/viewing_state_change_notifier.dart';
import 'package:sofawatch/features/history/domain/models/history_episode.dart';
import 'package:sofawatch/features/history/domain/models/history_episode_item.dart';
import 'package:sofawatch/features/history/domain/models/history_item.dart';
import 'package:sofawatch/features/history/domain/models/history_media_type.dart';
import 'package:sofawatch/features/history/domain/models/history_movie_item.dart';
import 'package:sofawatch/features/history/domain/models/history_page.dart';
import 'package:sofawatch/features/history/domain/models/history_preview.dart';
import 'package:sofawatch/features/history/domain/repositories/history_repository.dart';
import 'package:sofawatch/features/home/application/cubit/home_cubit.dart';
import 'package:sofawatch/features/home/application/models/home_watch_source.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';
import 'package:sofawatch/features/shows/domain/models/stale_watching_show.dart';
import 'package:sofawatch/features/shows/domain/models/upcoming_episode.dart';
import 'package:sofawatch/features/shows/domain/models/upcoming_item.dart';
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

HomeCubit _createHomeCubit({
  required ViewingStateChangeNotifier viewingStateChangeNotifier,
  required ShowsRepository repository,
  HistoryRepository? historyRepository,
  DateTime Function()? now,
}) {
  return HomeCubit(
    viewingStateChangeNotifier: viewingStateChangeNotifier,
    repository: repository,
    historyRepository: historyRepository ?? _FakeHistoryRepository(),
    now: now,
  );
}

void main() {
  late ViewingStateChangeNotifier viewingStateChangeNotifier;

  setUp(() {
    viewingStateChangeNotifier = ViewingStateChangeNotifier();
  });

  tearDown(() async {
    await viewingStateChangeNotifier.dispose();
  });
  group('HomeCubit', () {
    test(
      'refreshes only viewing-dependent sections after viewing state changes',
      () async {
        final _FakeShowsRepository repository = _FakeShowsRepository();
        final _FakeHistoryRepository historyRepository =
            _FakeHistoryRepository();

        final HomeCubit cubit = _createHomeCubit(
          viewingStateChangeNotifier: viewingStateChangeNotifier,
          repository: repository,
          historyRepository: historyRepository,
          now: () => _referenceToday,
        );

        viewingStateChangeNotifier.notifyChanged();

        /*
     * The notifier listener intentionally dispatches the refresh without
     * blocking the mutation that produced the event.
     *
     * Allow the three async section loaders to complete.
     */
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(repository.watchNextCalls, 1);
        expect(repository.missedRecentlyCalls, 1);
        expect(historyRepository.historyCalls, 1);
        expect(repository.watchHistoryCalls, 0);

        /*
     * Upcoming powers both Premiering Today and Upcoming.
     *
     * Neither collection depends on watched state, so no request should be
     * made for them.
     */
        expect(repository.upcomingCalls, 0);

        await cubit.close();
      },
    );
  });
  group('HomeCubit Premiering Today', () {
    test('loads yesterday and today and limits Home results', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        upcoming: List<UpcomingItem>.generate(
          8,
          (int index) => _upcomingItem(
            episodeId: 'episode-$index',
            airDate: _referenceToday,
          ),
        ),
      );

      final HomeCubit cubit = _createHomeCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
        now: () => DateTime(2026, 8, 17, 14, 30),
      );

      await cubit.loadPremieringToday();

      expect(
        cubit.state.premieringToday,
        hasLength(HomeCubit.premieringTodayLimit),
      );

      expect(
        repository.requestedFromDate,
        _referenceToday.subtract(const Duration(days: 1)),
      );

      expect(repository.requestedToDate, _referenceToday);
      expect(repository.requestedUpcomingLimit, HomeCubit.premieringTodayLimit);

      await cubit.close();
    });

    test(
      'uses the injected current day window when the date advances',
      () async {
        final DateTime simulatedToday = DateTime(2026, 8, 18);

        final _FakeShowsRepository repository = _FakeShowsRepository(
          upcoming: <UpcomingItem>[
            _upcomingItem(episodeId: 'episode-18', airDate: simulatedToday),
          ],
        );

        final HomeCubit cubit = _createHomeCubit(
          viewingStateChangeNotifier: viewingStateChangeNotifier,
          repository: repository,
          now: () => DateTime(2026, 8, 18, 9, 15),
        );

        await cubit.loadPremieringToday();

        expect(repository.requestedFromDate, DateTime(2026, 8, 17));

        expect(repository.requestedToDate, simulatedToday);

        await cubit.close();
      },
    );

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

      final HomeCubit cubit = _createHomeCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
        now: () => _referenceToday,
      );

      await cubit.loadPremieringToday();

      expect(cubit.state.premieringToday.single.episode.isWatched, isFalse);

      await cubit.markPremieringTodayEpisodeWatched(episodeId: 'episode-1');

      expect(repository.markWatchedCalls, 1);

      expect(cubit.state.premieringToday, isEmpty);

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

      final HomeCubit cubit = _createHomeCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
        now: () => _referenceToday,
      );

      await cubit.loadPremieringToday();

      await cubit.markEpisodeWatched(
        episodeId: 'episode-1',
        source: HomeWatchSource.premieringToday,
      );

      expect(repository.markWatchedCalls, 1);

      expect(cubit.state.premieringToday, isEmpty);

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

      final HomeCubit cubit = _createHomeCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
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

      final HomeCubit cubit = _createHomeCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
        now: () => _referenceToday,
      );

      await cubit.loadPremieringToday();

      await cubit.markPremieringTodayEpisodeWatched(episodeId: 'episode-1');

      expect(repository.markWatchedCalls, 0);
      expect(repository.watchHistoryCalls, 0);

      await cubit.close();
    });
    test('Retry reloads Premiering Today after failure', () async {
      final UpcomingItem item = _upcomingItem(
        episodeId: 'episode-retry',
        airDate: _referenceToday,
      );

      final _FakeShowsRepository repository = _FakeShowsRepository(
        upcoming: <UpcomingItem>[item],
        failUpcoming: true,
      );

      final HomeCubit cubit = _createHomeCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
        now: () => _referenceToday,
      );

      await cubit.loadPremieringToday();

      expect(repository.upcomingCalls, 1);
      expect(cubit.state.premieringTodayError, isA<AppException>());

      repository.failUpcoming = false;

      await cubit.retryPremieringToday();

      expect(repository.upcomingCalls, 2);
      expect(cubit.state.premieringToday, <UpcomingItem>[item]);
      expect(cubit.state.premieringTodayError, isNull);

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

      final HomeCubit cubit = _createHomeCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
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

      final HomeCubit cubit = _createHomeCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
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

      final HomeCubit cubit = _createHomeCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
        now: () => _referenceToday,
      );

      await cubit.loadUpcoming();
      expect(repository.requestedUpcomingLimit, HomeCubit.upcomingLimit);

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

      final HomeCubit cubit = _createHomeCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
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

      final HomeCubit cubit = _createHomeCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
        now: () => _referenceToday,
      );

      await cubit.loadUpcoming();

      expect(cubit.state.upcoming, isEmpty);
      expect(cubit.state.upcomingError, isA<AppException>());
      expect(cubit.state.isLoadingUpcoming, isFalse);

      await cubit.close();
    });
    test('Retry reloads only Upcoming after failure', () async {
      final UpcomingItem item = _upcomingItem(
        episodeId: 'episode-retry',
        airDate: _relativeDay(1),
      );

      final _FakeShowsRepository repository = _FakeShowsRepository(
        upcoming: <UpcomingItem>[item],
        failUpcoming: true,
      );

      final HomeCubit cubit = _createHomeCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
        now: () => _referenceToday,
      );

      await cubit.loadUpcoming();

      expect(repository.upcomingCalls, 1);
      expect(cubit.state.upcomingError, isA<AppException>());

      repository.failUpcoming = false;

      await cubit.retryUpcoming();

      expect(repository.upcomingCalls, 2);
      expect(cubit.state.upcoming, <UpcomingItem>[item]);
      expect(cubit.state.upcomingError, isNull);

      await cubit.close();
    });
  });

  group('HomeCubit Missed Recently', () {
    test('loads the backend-owned Missed Recently collection', () async {
      final List<UpcomingItem> missedRecently = <UpcomingItem>[
        _upcomingItem(episodeId: 'episode-1', airDate: _relativeDay(-1)),
        _upcomingItem(episodeId: 'episode-2', airDate: _relativeDay(-2)),
      ];

      final _FakeShowsRepository repository = _FakeShowsRepository(
        missedRecently: missedRecently,
      );

      final HomeCubit cubit = _createHomeCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
        now: () => _referenceToday,
      );

      await cubit.loadMissedRecently();

      expect(repository.missedRecentlyCalls, 1);

      expect(cubit.state.missedRecently, missedRecently);

      expect(cubit.state.isLoadingMissedRecently, isFalse);
      expect(cubit.state.missedRecentlyError, isNull);

      await cubit.close();
    });

    test('does not re-filter the backend Missed Recently collection', () async {
      final List<UpcomingItem> serverResult = <UpcomingItem>[
        _upcomingItem(episodeId: 'episode-1', airDate: _relativeDay(-1)),
        _upcomingItem(episodeId: 'episode-2', airDate: _relativeDay(-2)),
      ];

      final _FakeShowsRepository repository = _FakeShowsRepository(
        missedRecently: serverResult,
      );

      final HomeCubit cubit = _createHomeCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
        now: () => _referenceToday,
      );

      await cubit.loadMissedRecently();

      /*
       * Filtering, ordering and limiting are backend responsibilities.
       *
       * Home preserves the server-owned collection exactly as received.
       */
      expect(cubit.state.missedRecently, serverResult);

      await cubit.close();
    });

    test('stores Missed Recently errors independently', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        failMissedRecently: true,
      );

      final HomeCubit cubit = _createHomeCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
        now: () => _referenceToday,
      );

      await cubit.loadMissedRecently();

      expect(repository.missedRecentlyCalls, 1);

      expect(cubit.state.missedRecently, isEmpty);
      expect(cubit.state.missedRecentlyError, isA<AppException>());
      expect(cubit.state.isLoadingMissedRecently, isFalse);

      await cubit.close();
    });

    test('removes Episode after marking it watched', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        missedRecently: <UpcomingItem>[
          _upcomingItem(episodeId: 'episode-1', airDate: _relativeDay(-1)),
          _upcomingItem(episodeId: 'episode-2', airDate: _relativeDay(-2)),
        ],
      );

      final HomeCubit cubit = _createHomeCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
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

      await cubit.close();
    });

    test('restores Episode when marking it watched fails', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        missedRecently: <UpcomingItem>[
          _upcomingItem(episodeId: 'episode-1', airDate: _relativeDay(-1)),
        ],
        failMarkWatched: true,
      );

      final HomeCubit cubit = _createHomeCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
        now: () => _referenceToday,
      );

      await cubit.loadMissedRecently();

      await cubit.markMissedRecentlyEpisodeWatched(episodeId: 'episode-1');

      expect(cubit.state.missedRecently, hasLength(1));
      expect(cubit.state.missedRecently.single.episode.id, 'episode-1');

      expect(cubit.state.watchOperationError, isA<AppException>());

      await cubit.close();
    });
  });

  group('HomeCubit Recent Activity', () {
    test('loads only a small mixed Recent Activity page', () async {
      final List<HistoryItem> items = List<HistoryItem>.generate(8, (
        int index,
      ) {
        if (index.isEven) {
          return _historyEpisodeItem(
            eventId: 'event-$index',
            episodeId: 'episode-$index',
            watchedAt: DateTime.utc(
              2026,
              8,
              17,
              20,
            ).subtract(Duration(minutes: index)),
          );
        }

        return _historyMovieItem(
          eventId: 'event-$index',
          movieId: 'movie-$index',
          watchedAt: DateTime.utc(
            2026,
            8,
            17,
            20,
          ).subtract(Duration(minutes: index)),
        );
      });

      final _FakeShowsRepository repository = _FakeShowsRepository();
      final _FakeHistoryRepository historyRepository = _FakeHistoryRepository(
        page: HistoryPage(items: items, hasMore: true, nextCursor: 'next'),
      );

      final HomeCubit cubit = _createHomeCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
        historyRepository: historyRepository,
        now: () => _referenceToday,
      );

      await cubit.loadRecentActivity();

      expect(historyRepository.historyCalls, 1);
      expect(historyRepository.requestedLimit, HomeCubit.recentActivityLimit);
      expect(historyRepository.requestedMediaType, HistoryMediaType.all);
      expect(repository.watchHistoryCalls, 0);

      expect(
        cubit.state.recentActivity,
        hasLength(HomeCubit.recentActivityLimit),
      );
      expect(cubit.state.recentActivity.first.eventId, 'event-0');
      expect(cubit.state.recentActivity, contains(isA<HistoryEpisodeItem>()));
      expect(cubit.state.recentActivity, contains(isA<HistoryMovieItem>()));

      await cubit.close();
    });

    test('keeps global History order unchanged', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository();
      final _FakeHistoryRepository historyRepository = _FakeHistoryRepository(
        page: HistoryPage(
          items: <HistoryItem>[
            _historyMovieItem(
              eventId: 'newest',
              movieId: 'movie-1',
              watchedAt: DateTime.utc(2026, 8, 17, 23),
            ),
            _historyEpisodeItem(
              eventId: 'middle',
              episodeId: 'episode-1',
              watchedAt: DateTime.utc(2026, 8, 17, 22),
            ),
            _historyMovieItem(
              eventId: 'oldest',
              movieId: 'movie-2',
              watchedAt: DateTime.utc(2026, 8, 17, 21),
            ),
          ],
          hasMore: false,
        ),
      );

      final HomeCubit cubit = _createHomeCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
        historyRepository: historyRepository,
        now: () => _referenceToday,
      );

      await cubit.loadRecentActivity();

      expect(
        cubit.state.recentActivity.map((HistoryItem item) => item.eventId),
        <String>['newest', 'middle', 'oldest'],
      );

      await cubit.close();
    });

    test('stores Recent Activity errors independently', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository();
      final _FakeHistoryRepository historyRepository = _FakeHistoryRepository(
        failHistory: true,
      );

      final HomeCubit cubit = _createHomeCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
        historyRepository: historyRepository,
        now: () => _referenceToday,
      );

      await cubit.loadRecentActivity();

      expect(cubit.state.recentActivity, isEmpty);
      expect(cubit.state.recentActivityError, isA<AppException>());
      expect(cubit.state.isLoadingRecentActivity, isFalse);
      expect(historyRepository.historyCalls, 1);
      expect(repository.watchHistoryCalls, 0);

      await cubit.close();
    });

    test('Retry reloads only Recent Activity after failure', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository();
      final _FakeHistoryRepository historyRepository = _FakeHistoryRepository(
        failHistory: true,
      );

      final HomeCubit cubit = _createHomeCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
        historyRepository: historyRepository,
        now: () => _referenceToday,
      );

      await cubit.loadRecentActivity();

      expect(historyRepository.historyCalls, 1);
      expect(cubit.state.recentActivityError, isA<AppException>());

      final HistoryMovieItem item = _historyMovieItem(
        eventId: 'event-retry',
        movieId: 'movie-retry',
        watchedAt: DateTime.utc(2026, 8, 16, 20),
      );

      historyRepository
        ..failHistory = false
        ..page = HistoryPage(items: <HistoryItem>[item], hasMore: false);

      await cubit.retryRecentActivity();

      expect(historyRepository.historyCalls, 2);
      expect(cubit.state.recentActivity, <HistoryItem>[item]);
      expect(cubit.state.recentActivityError, isNull);
      expect(repository.watchHistoryCalls, 0);

      await cubit.close();
    });
  });

  group('HomeCubit cross-section watched updates', () {
    test('marks Premiering Today watched and removes same Episode from '
        'Missed Recently', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository();

      final HomeCubit cubit = _createHomeCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
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

      expect(cubit.state.premieringToday, isEmpty);

      expect(cubit.state.missedRecently, isEmpty);

      expect(repository.markWatchedCalls, 1);

      await cubit.close();
    });

    test('marking a missed Episode updates Premiering Today when the '
        'same Episode is present', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository();

      final HomeCubit cubit = _createHomeCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
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

      expect(cubit.state.premieringToday, isEmpty);

      expect(cubit.state.missedRecently, isEmpty);

      await cubit.close();
    });

    test(
      'refreshes Recent Activity after a successful watched mutation',
      () async {
        final HistoryEpisodeItem newActivity = _historyEpisodeItem(
          eventId: 'new-event',
          episodeId: 'episode-1',
          watchedAt: DateTime.utc(2026, 8, 17, 21),
        );

        final _FakeShowsRepository repository = _FakeShowsRepository();
        final _FakeHistoryRepository historyRepository = _FakeHistoryRepository(
          page: HistoryPage(items: <HistoryItem>[newActivity], hasMore: false),
        );

        final HomeCubit cubit = _createHomeCubit(
          viewingStateChangeNotifier: viewingStateChangeNotifier,
          repository: repository,
          historyRepository: historyRepository,
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

        expect(historyRepository.historyCalls, 1);
        expect(repository.watchHistoryCalls, 0);

        expect(historyRepository.requestedLimit, HomeCubit.recentActivityLimit);

        expect(cubit.state.recentActivity.single.eventId, 'new-event');

        await cubit.close();
      },
    );

    test('rolls back all deterministic cross-section changes when '
        'mutation fails', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        failMarkWatched: true,
      );
      final _FakeHistoryRepository historyRepository = _FakeHistoryRepository();

      final HomeCubit cubit = _createHomeCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
        historyRepository: historyRepository,
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
       * Failed writes must not fabricate or refresh server-owned
       * global History.
       */
      expect(historyRepository.historyCalls, 0);
      expect(repository.watchHistoryCalls, 0);

      await cubit.close();
    });

    test(
      'does not reload unrelated Upcoming data after watched mutation',
      () async {
        final _FakeShowsRepository repository = _FakeShowsRepository();
        final _FakeHistoryRepository historyRepository =
            _FakeHistoryRepository();

        final HomeCubit cubit = _createHomeCubit(
          viewingStateChangeNotifier: viewingStateChangeNotifier,
          repository: repository,
          historyRepository: historyRepository,
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
        expect(historyRepository.historyCalls, 1);
        expect(repository.watchHistoryCalls, 0);

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
        );
        final _FakeHistoryRepository historyRepository = _FakeHistoryRepository(
          page: HistoryPage(
            items: <HistoryItem>[
              _historyEpisodeItem(
                eventId: 'event-1',
                episodeId: 'episode-1',
                watchedAt: DateTime.utc(2026, 8, 17, 20),
              ),
            ],
            hasMore: false,
          ),
        );

        final HomeCubit cubit = _createHomeCubit(
          viewingStateChangeNotifier: viewingStateChangeNotifier,
          repository: repository,
          historyRepository: historyRepository,
          now: () => _referenceToday,
        );

        await cubit.loadPremieringToday();

        expect(cubit.state.premieringToday.single.episode.isWatched, isFalse);

        await cubit.markPremieringTodayEpisodeWatched(episodeId: 'episode-1');

        expect(repository.markWatchedCalls, 1);

        expect(cubit.state.premieringToday, isEmpty);

        expect(historyRepository.historyCalls, 1);
        expect(repository.watchHistoryCalls, 0);

        final HistoryItem activity = cubit.state.recentActivity.single;
        expect(activity, isA<HistoryEpisodeItem>());
        expect((activity as HistoryEpisodeItem).episode.id, 'episode-1');

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
          missedRecently: <UpcomingItem>[
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
        );
        final _FakeHistoryRepository historyRepository = _FakeHistoryRepository(
          page: HistoryPage(
            items: <HistoryItem>[
              _historyEpisodeItem(
                eventId: 'event-1',
                episodeId: 'episode-1',
                watchedAt: DateTime.utc(2026, 8, 17, 20),
              ),
            ],
            hasMore: false,
          ),
        );

        final HomeCubit cubit = _createHomeCubit(
          viewingStateChangeNotifier: viewingStateChangeNotifier,
          repository: repository,
          historyRepository: historyRepository,
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

        expect(historyRepository.historyCalls, 1);
        expect(repository.watchHistoryCalls, 0);

        final HistoryItem activity = cubit.state.recentActivity.single;
        expect(activity, isA<HistoryEpisodeItem>());
        expect((activity as HistoryEpisodeItem).episode.id, 'episode-1');

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
        );
        final _FakeHistoryRepository historyRepository = _FakeHistoryRepository(
          page: HistoryPage(
            items: <HistoryItem>[
              _historyEpisodeItem(
                eventId: 'event-1',
                episodeId: 'episode-1',
                watchedAt: DateTime.utc(2026, 8, 17, 20),
              ),
            ],
            hasMore: false,
          ),
        );

        final HomeCubit cubit = _createHomeCubit(
          viewingStateChangeNotifier: viewingStateChangeNotifier,
          repository: repository,
          historyRepository: historyRepository,
          now: () => _referenceToday,
        );

        await cubit.loadContinueWatching();
        expect(
          repository.requestedWatchNextLimit,
          HomeCubit.continueWatchingLimit,
        );

        expect(cubit.state.continueWatching.single.nextEpisode.id, 'episode-1');

        await cubit.markContinueWatchingEpisodeWatched(episodeId: 'episode-1');

        expect(repository.markWatchedCalls, 1);

        expect(repository.watchNextCalls, 2);

        expect(cubit.state.continueWatching.single.nextEpisode.id, 'episode-2');

        expect(historyRepository.historyCalls, 1);
        expect(repository.watchHistoryCalls, 0);

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

        final _FakeShowsRepository repository = _FakeShowsRepository();

        final HomeCubit cubit = _createHomeCubit(
          viewingStateChangeNotifier: viewingStateChangeNotifier,
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

        expect(cubit.state.premieringToday, isEmpty);

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
        final _FakeHistoryRepository historyRepository =
            _FakeHistoryRepository();

        final HomeCubit cubit = _createHomeCubit(
          viewingStateChangeNotifier: viewingStateChangeNotifier,
          repository: repository,
          historyRepository: historyRepository,
          now: () => _referenceToday,
        );

        await cubit.loadPremieringToday();

        await cubit.markPremieringTodayEpisodeWatched(episodeId: 'episode-1');

        expect(cubit.state.premieringToday.single.episode.isWatched, isFalse);

        expect(cubit.state.updatingEpisodeId, isNull);
        expect(cubit.state.updatingEpisodeSource, isNull);
        expect(cubit.state.watchOperationError, isA<AppException>());

        expect(historyRepository.historyCalls, 0);
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
        );
        final _FakeHistoryRepository historyRepository =
            _FakeHistoryRepository();

        final HomeCubit cubit = _createHomeCubit(
          viewingStateChangeNotifier: viewingStateChangeNotifier,
          repository: repository,
          historyRepository: historyRepository,
          now: () => _referenceToday,
        );

        await cubit.loadPremieringToday();

        final int upcomingCallsBefore = repository.upcomingCalls;
        final int watchNextCallsBefore = repository.watchNextCalls;
        final int historyCallsBefore = historyRepository.historyCalls;

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
         * Recent Activity is backed by global History. The backend owns
         * event IDs, watched timestamps and newest-first ordering.
         */
        expect(historyRepository.historyCalls, historyCallsBefore + 1);
        expect(repository.watchHistoryCalls, 0);

        expect(repository.markWatchedCalls, 1);

        await cubit.close();
      },
    );
    group('HomeCubit partial failures', () {
      test(
        'one failed section does not block the remaining Home sections',
        () async {
          final UpcomingItem upcomingItem = _upcomingItem(
            episodeId: 'upcoming-episode',
            airDate: _relativeDay(1),
          );

          final WatchNextShow continueWatchingItem = _watchNextShow(
            episodeId: 'continue-episode',
          );

          final HistoryEpisodeItem recentItem = _historyEpisodeItem(
            eventId: 'recent-event',
            episodeId: 'recent-episode',
            watchedAt: DateTime.utc(2026, 8, 16, 20),
          );

          final _FakeShowsRepository repository = _FakeShowsRepository(
            upcoming: <UpcomingItem>[upcomingItem],
            watchNextResponses: <List<WatchNextShow>>[
              <WatchNextShow>[continueWatchingItem],
            ],
            failMissedRecently: true,
          );
          final _FakeHistoryRepository historyRepository =
              _FakeHistoryRepository(
                page: HistoryPage(
                  items: <HistoryItem>[recentItem],
                  hasMore: false,
                ),
              );

          final HomeCubit cubit = _createHomeCubit(
            viewingStateChangeNotifier: viewingStateChangeNotifier,
            repository: repository,
            historyRepository: historyRepository,
            now: () => _referenceToday,
          );

          await cubit.load();

          expect(cubit.state.missedRecently, isEmpty);
          expect(cubit.state.missedRecentlyError, isA<AppException>());

          expect(cubit.state.continueWatching, isNotEmpty);
          expect(cubit.state.premieringToday, isNotEmpty);
          expect(cubit.state.upcoming, isNotEmpty);
          expect(cubit.state.recentActivity, isNotEmpty);

          await cubit.close();
        },
      );
    });
    test('retry reloads only the failed Missed Recently section', () async {
      final UpcomingItem item = _upcomingItem(
        episodeId: 'episode-1',
        airDate: _relativeDay(-1),
      );

      final _FakeShowsRepository repository = _FakeShowsRepository(
        missedRecently: <UpcomingItem>[item],
        failMissedRecently: true,
      );

      final HomeCubit cubit = _createHomeCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
        now: () => _referenceToday,
      );

      await cubit.loadMissedRecently();

      expect(repository.missedRecentlyCalls, 1);
      expect(cubit.state.missedRecentlyError, isNotNull);

      repository.failMissedRecently = false;

      await cubit.retryMissedRecently();

      expect(repository.missedRecentlyCalls, 2);
      expect(cubit.state.missedRecently, <UpcomingItem>[item]);
      expect(cubit.state.missedRecentlyError, isNull);

      await cubit.close();
    });
    test('failed partial refresh preserves existing Upcoming data', () async {
      final UpcomingItem existingItem = _upcomingItem(
        episodeId: 'episode-existing',
        airDate: _relativeDay(1),
      );

      final _FakeShowsRepository repository = _FakeShowsRepository(
        upcoming: <UpcomingItem>[existingItem],
      );

      final HomeCubit cubit = _createHomeCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
        now: () => _referenceToday,
      );

      await cubit.loadUpcoming();

      expect(cubit.state.upcoming, <UpcomingItem>[existingItem]);

      repository.failUpcoming = true;

      await cubit.loadUpcoming();

      expect(cubit.state.upcoming, <UpcomingItem>[existingItem]);

      expect(cubit.state.upcomingError, isA<AppException>());

      expect(cubit.state.isLoadingUpcoming, isFalse);

      await cubit.close();
    });
    group('HomeCubit refresh', () {
      test('refreshes every server-owned Home section', () async {
        final _FakeShowsRepository repository = _FakeShowsRepository();
        final _FakeHistoryRepository historyRepository =
            _FakeHistoryRepository();

        final HomeCubit cubit = _createHomeCubit(
          viewingStateChangeNotifier: viewingStateChangeNotifier,
          repository: repository,
          historyRepository: historyRepository,
          now: () => _referenceToday,
        );

        final bool succeeded = await cubit.refresh();

        expect(succeeded, isTrue);

        expect(repository.watchNextCalls, 1);

        /*
     * Upcoming is requested twice:
     *
     * - Premiering Today;
     * - Upcoming.
     */
        expect(repository.upcomingCalls, 2);

        expect(repository.missedRecentlyCalls, 1);

        expect(historyRepository.historyCalls, 1);
        expect(repository.watchHistoryCalls, 0);

        await cubit.close();
      });

      test(
        'reports a partial refresh failure without blocking other sections',
        () async {
          final _FakeShowsRepository repository = _FakeShowsRepository(
            failMissedRecently: true,
          );
          final _FakeHistoryRepository historyRepository =
              _FakeHistoryRepository();

          final HomeCubit cubit = _createHomeCubit(
            viewingStateChangeNotifier: viewingStateChangeNotifier,
            repository: repository,
            historyRepository: historyRepository,
            now: () => _referenceToday,
          );

          final bool succeeded = await cubit.refresh();

          expect(succeeded, isFalse);

          expect(repository.watchNextCalls, 1);
          expect(repository.upcomingCalls, 2);
          expect(repository.missedRecentlyCalls, 1);
          expect(historyRepository.historyCalls, 1);
          expect(repository.watchHistoryCalls, 0);

          expect(cubit.state.missedRecentlyError, isA<AppException>());

          await cubit.close();
        },
      );
    });
    test('Retry reloads only Continue Watching after failure', () async {
      final WatchNextShow item = _watchNextShow(episodeId: 'episode-retry');

      final _FakeShowsRepository repository = _FakeShowsRepository(
        watchNextResponses: <List<WatchNextShow>>[
          <WatchNextShow>[item],
        ],
        failWatchNext: true,
      );

      final HomeCubit cubit = _createHomeCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
        now: () => _referenceToday,
      );

      await cubit.loadContinueWatching();

      expect(repository.watchNextCalls, 1);
      expect(cubit.state.continueWatchingError, isA<AppException>());

      repository.failWatchNext = false;

      await cubit.retryContinueWatching();

      expect(repository.watchNextCalls, 2);
      expect(cubit.state.continueWatching, <WatchNextShow>[item]);
      expect(cubit.state.continueWatchingError, isNull);

      await cubit.close();
    });
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

HistoryEpisodeItem _historyEpisodeItem({
  required String eventId,
  required String episodeId,
  required DateTime watchedAt,
}) {
  return HistoryEpisodeItem(
    eventId: eventId,
    watchedAt: watchedAt,
    showId: 'show-$episodeId',
    showTmdbId: 95396,
    showTitle: 'Severance',
    posterUrl: null,
    backdropUrl: null,
    episode: HistoryEpisode(
      id: episodeId,
      tmdbId: 1000,
      seasonNumber: 2,
      episodeNumber: 1,
      title: 'Hello, Ms. Cobel',
      airDate: DateTime(2025, 1, 17),
      runtime: 52,
      stillUrl: null,
    ),
  );
}

HistoryMovieItem _historyMovieItem({
  required String eventId,
  required String movieId,
  required DateTime watchedAt,
  int tmdbId = 157336,
  String title = 'Interstellar',
}) {
  return HistoryMovieItem(
    eventId: eventId,
    watchedAt: watchedAt,
    movieId: movieId,
    movieTmdbId: tmdbId,
    movieTitle: title,
    posterUrl: null,
    backdropUrl: null,
  );
}

final class _FakeShowsRepository implements ShowsRepository {
  _FakeShowsRepository({
    this.upcoming = const <UpcomingItem>[],
    this.failMarkWatched = false,
    this.failUpcoming = false,
    this.watchNextResponses = const <List<WatchNextShow>>[],
    this.missedRecently = const <UpcomingItem>[],
    this.failMissedRecently = false,
    this.failWatchNext = false,
  });

  final List<UpcomingItem> upcoming;

  final bool failMarkWatched;
  bool failUpcoming;

  bool failWatchNext;

  DateTime? requestedFromDate;
  DateTime? requestedToDate;

  int? requestedUpcomingLimit;

  int? requestedWatchHistoryLimit;

  int upcomingCalls = 0;
  int markWatchedCalls = 0;
  int watchHistoryCalls = 0;

  int watchNextCalls = 0;

  final List<List<WatchNextShow>> watchNextResponses;

  int _watchNextResponseIndex = 0;

  final List<UpcomingItem> missedRecently;

  bool failMissedRecently;

  int missedRecentlyCalls = 0;

  int? requestedWatchNextLimit;

  @override
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    upcomingCalls++;

    requestedFromDate = fromDate;
    requestedToDate = toDate;
    requestedUpcomingLimit = limit;

    if (failUpcoming) {
      throw const AppException.connection();
    }

    if (limit == null) {
      return upcoming;
    }

    return upcoming.take(limit).toList(growable: false);
  }

  @override
  Future<List<WatchNextShow>> getWatchNext({int? limit}) async {
    watchNextCalls++;
    requestedWatchNextLimit = limit;

    if (failWatchNext) {
      throw const AppException.connection();
    }

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

    if (limit == null) {
      return result;
    }

    return result.take(limit).toList(growable: false);
  }

  @override
  Future<WatchHistoryPage> getWatchHistory({
    int limit = 30,
    String? cursor,
  }) async {
    watchHistoryCalls++;
    requestedWatchHistoryLimit = limit;

    return const WatchHistoryPage(items: <WatchHistoryItem>[], hasMore: false);
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

  @override
  Future<List<UpcomingItem>> getMissedRecently() async {
    missedRecentlyCalls++;

    if (failMissedRecently) {
      throw const AppException.connection();
    }

    return missedRecently;
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

final class _FakeHistoryRepository implements HistoryRepository {
  _FakeHistoryRepository({
    this.page = const HistoryPage(items: <HistoryItem>[], hasMore: false),
    this.failHistory = false,
  });

  HistoryPage page;
  bool failHistory;

  int historyCalls = 0;
  int? requestedLimit;
  String? requestedCursor;
  HistoryMediaType? requestedMediaType;

  @override
  Future<HistoryPage> getHistory({
    int limit = 30,
    String? cursor,
    HistoryMediaType mediaType = HistoryMediaType.all,
  }) async {
    historyCalls++;
    requestedLimit = limit;
    requestedCursor = cursor;
    requestedMediaType = mediaType;

    if (failHistory) {
      throw const AppException.connection();
    }

    return page;
  }

  @override
  Future<HistoryPreview> getPreview() {
    throw UnimplementedError();
  }
}
