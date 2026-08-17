import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/home/application/cubit/home_cubit.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';
import 'package:sofawatch/features/shows/domain/models/stale_watching_show.dart';
import 'package:sofawatch/features/shows/domain/models/upcoming_episode.dart';
import 'package:sofawatch/features/shows/domain/models/upcoming_item.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_page.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_show.dart';
import 'package:sofawatch/features/shows/domain/repositories/shows_repository.dart';

void main() {
  group('HomeCubit Premiering Today', () {
    test('loads only today and limits Home results', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        upcoming: List<UpcomingItem>.generate(
          8,
          (int index) => _upcomingItem(episodeId: 'episode-$index'),
        ),
      );

      final HomeCubit cubit = HomeCubit(
        repository: repository,
        now: () => DateTime(2026, 8, 17, 14, 30),
      );

      await cubit.loadPremieringToday();

      expect(cubit.state.premieringToday, hasLength(5));

      expect(repository.requestedFromDate, DateTime(2026, 8, 17));

      expect(repository.requestedToDate, DateTime(2026, 8, 17));

      await cubit.close();
    });

    test('marks Premiering Today Episode as watched', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        upcoming: <UpcomingItem>[
          _upcomingItem(episodeId: 'episode-1', isWatched: false),
        ],
      );

      final HomeCubit cubit = HomeCubit(
        repository: repository,
        now: () => DateTime(2026, 8, 17),
      );

      await cubit.loadPremieringToday();

      expect(cubit.state.premieringToday.single.episode.isWatched, isFalse);

      await cubit.markPremieringTodayEpisodeWatched(episodeId: 'episode-1');

      expect(repository.markWatchedCalls, 1);

      expect(cubit.state.premieringToday.single.episode.isWatched, isTrue);

      expect(cubit.state.updatingPremieringTodayEpisodeId, isNull);

      await cubit.close();
    });

    test('rolls back optimistic watched state when mutation fails', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        upcoming: <UpcomingItem>[
          _upcomingItem(episodeId: 'episode-1', isWatched: false),
        ],
        failMarkWatched: true,
      );

      final HomeCubit cubit = HomeCubit(
        repository: repository,
        now: () => DateTime(2026, 8, 17),
      );

      await cubit.loadPremieringToday();

      await cubit.markPremieringTodayEpisodeWatched(episodeId: 'episode-1');

      expect(cubit.state.premieringToday.single.episode.isWatched, isFalse);

      expect(cubit.state.premieringTodayOperationError, isA<AppException>());

      await cubit.close();
    });

    test('does not record another watch for already watched Episode', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        upcoming: <UpcomingItem>[
          _upcomingItem(episodeId: 'episode-1', isWatched: true),
        ],
      );

      final HomeCubit cubit = HomeCubit(
        repository: repository,
        now: () => DateTime(2026, 8, 17),
      );

      await cubit.loadPremieringToday();

      await cubit.markPremieringTodayEpisodeWatched(episodeId: 'episode-1');

      expect(repository.markWatchedCalls, 0);

      await cubit.close();
    });
  });
}

UpcomingItem _upcomingItem({
  required String episodeId,
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
      airDate: DateTime(2026, 8, 17),
      runtime: 52,
      stillUrl: null,
      isWatched: isWatched,
    ),
  );
}

final class _FakeShowsRepository implements ShowsRepository {
  _FakeShowsRepository({
    this.upcoming = const <UpcomingItem>[],
    this.failMarkWatched = false,
  });

  final List<UpcomingItem> upcoming;

  final bool failMarkWatched;

  DateTime? requestedFromDate;
  DateTime? requestedToDate;

  int markWatchedCalls = 0;

  @override
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    requestedFromDate = fromDate;
    requestedToDate = toDate;

    return upcoming;
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
  Future<List<WatchNextShow>> getWatchNext() {
    throw UnimplementedError();
  }

  @override
  Future<List<StaleWatchingShow>> getStaleWatching() {
    throw UnimplementedError();
  }

  @override
  Future<WatchHistoryPage> getWatchHistory({int limit = 30, String? cursor}) {
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
