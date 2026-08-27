import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/core/viewing/viewing_state_change_notifier.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_show_operation.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_show_operation_cubit.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_episode.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_episode_progress.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_episode_watch_event.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_local_season.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_season_progress.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_seasons_bootstrap.dart';
import 'package:sofawatch/features/show_details/domain/repositories/show_details_seasons_repository.dart';

void main() {
  group('ShowDetailsShowOperationCubit', () {
    test('starts idle', () async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository();

      final ShowDetailsShowOperationCubit cubit = ShowDetailsShowOperationCubit(
        viewingStateChangeNotifier: ViewingStateChangeNotifier(),
        repository: repository,
        showTmdbId: 95396,
      );

      expect(cubit.state, const ShowDetailsShowOperation.idle());

      await cubit.close();
    });

    test('marks the resolved local Show as watched', () async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository();

      final ShowDetailsShowOperationCubit cubit = ShowDetailsShowOperationCubit(
        viewingStateChangeNotifier: ViewingStateChangeNotifier(),
        repository: repository,
        showTmdbId: 95396,
      );

      final List<ShowDetailsShowOperation> states =
          <ShowDetailsShowOperation>[];

      final StreamSubscription<ShowDetailsShowOperation> subscription = cubit
          .stream
          .listen(states.add);

      await cubit.markShowWatched();
      await Future<void>.delayed(Duration.zero);

      expect(repository.resolveLocalSeasonsCalls, 1);
      expect(repository.requestedShowTmdbIds, <int>[95396]);

      expect(repository.markShowWatchedCalls, 1);
      expect(repository.requestedShowIds, <String>['show-uuid']);

      expect(states, <ShowDetailsShowOperation>[
        const ShowDetailsShowOperation.updating(),
        const ShowDetailsShowOperation.success(),
      ]);

      expect(cubit.state.isSuccess, isTrue);

      await subscription.cancel();
      await cubit.close();
    });

    test('reuses the resolved local Show on subsequent operations', () async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository();

      final ShowDetailsShowOperationCubit cubit = ShowDetailsShowOperationCubit(
        viewingStateChangeNotifier: ViewingStateChangeNotifier(),
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.markShowWatched();

      cubit.reset();

      await cubit.markShowWatched();

      expect(repository.resolveLocalSeasonsCalls, 1);

      expect(repository.markShowWatchedCalls, 2);

      expect(repository.requestedShowIds, <String>['show-uuid', 'show-uuid']);

      await cubit.close();
    });

    test('emits failure when marking the Show fails', () async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository(failMarkShowWatched: true);

      final ShowDetailsShowOperationCubit cubit = ShowDetailsShowOperationCubit(
        viewingStateChangeNotifier: ViewingStateChangeNotifier(),
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.markShowWatched();

      expect(cubit.state.hasFailed, isTrue);

      expect(cubit.state.error?.type, AppExceptionType.connection);

      expect(repository.resolveLocalSeasonsCalls, 1);
      expect(repository.markShowWatchedCalls, 1);

      await cubit.close();
    });

    test('retry repeats a failed Show watched operation', () async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository(failMarkShowWatched: true);

      final ShowDetailsShowOperationCubit cubit = ShowDetailsShowOperationCubit(
        viewingStateChangeNotifier: ViewingStateChangeNotifier(),
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.markShowWatched();

      expect(cubit.state.hasFailed, isTrue);
      expect(repository.markShowWatchedCalls, 1);

      repository.failMarkShowWatched = false;

      await cubit.retryMarkShowWatched();

      expect(repository.resolveLocalSeasonsCalls, 1);
      expect(repository.markShowWatchedCalls, 2);

      expect(cubit.state.isSuccess, isTrue);

      await cubit.close();
    });

    test('retry does nothing unless the previous operation failed', () async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository();

      final ShowDetailsShowOperationCubit cubit = ShowDetailsShowOperationCubit(
        viewingStateChangeNotifier: ViewingStateChangeNotifier(),
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.retryMarkShowWatched();

      expect(repository.resolveLocalSeasonsCalls, 0);
      expect(repository.markShowWatchedCalls, 0);

      await cubit.close();
    });

    test('prevents double submission while operation is running', () async {
      final Completer<void> markCompleter = Completer<void>();

      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository(
            markShowWatchedCompleter: markCompleter,
          );

      final ShowDetailsShowOperationCubit cubit = ShowDetailsShowOperationCubit(
        viewingStateChangeNotifier: ViewingStateChangeNotifier(),
        repository: repository,
        showTmdbId: 95396,
      );

      final Future<void> firstOperation = cubit.markShowWatched();

      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.isUpdating, isTrue);
      expect(repository.markShowWatchedCalls, 1);

      await cubit.markShowWatched();

      expect(repository.markShowWatchedCalls, 1);

      markCompleter.complete();

      await firstOperation;

      expect(cubit.state.isSuccess, isTrue);
      expect(repository.markShowWatchedCalls, 1);

      await cubit.close();
    });

    test('reset returns a completed operation to idle', () async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository();

      final ShowDetailsShowOperationCubit cubit = ShowDetailsShowOperationCubit(
        viewingStateChangeNotifier: ViewingStateChangeNotifier(),
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.markShowWatched();

      expect(cubit.state.isSuccess, isTrue);

      cubit.reset();

      expect(cubit.state, const ShowDetailsShowOperation.idle());

      await cubit.close();
    });

    test('reset does nothing while operation is running', () async {
      final Completer<void> markCompleter = Completer<void>();

      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository(
            markShowWatchedCompleter: markCompleter,
          );

      final ShowDetailsShowOperationCubit cubit = ShowDetailsShowOperationCubit(
        viewingStateChangeNotifier: ViewingStateChangeNotifier(),
        repository: repository,
        showTmdbId: 95396,
      );

      final Future<void> operation = cubit.markShowWatched();

      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.isUpdating, isTrue);

      cubit.reset();

      expect(cubit.state.isUpdating, isTrue);

      markCompleter.complete();

      await operation;
      await cubit.close();
    });
    test('notifies viewing state after marking the Show watched', () async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository();

      final ViewingStateChangeNotifier notifier = ViewingStateChangeNotifier();

      int notifications = 0;

      final StreamSubscription<void> subscription = notifier.changes.listen((
        _,
      ) {
        notifications++;
      });

      final ShowDetailsShowOperationCubit cubit = ShowDetailsShowOperationCubit(
        viewingStateChangeNotifier: notifier,
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.markShowWatched();

      expect(repository.markShowWatchedCalls, 1);
      expect(cubit.state.isSuccess, isTrue);
      expect(notifications, 1);

      await subscription.cancel();
      await cubit.close();
      await notifier.dispose();
    });

    test('does not notify viewing state when marking the Show fails', () async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository(failMarkShowWatched: true);

      final ViewingStateChangeNotifier notifier = ViewingStateChangeNotifier();

      int notifications = 0;

      final StreamSubscription<void> subscription = notifier.changes.listen((
        _,
      ) {
        notifications++;
      });

      final ShowDetailsShowOperationCubit cubit = ShowDetailsShowOperationCubit(
        viewingStateChangeNotifier: notifier,
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.markShowWatched();

      expect(repository.markShowWatchedCalls, 1);
      expect(cubit.state.hasFailed, isTrue);
      expect(notifications, 0);

      await subscription.cancel();
      await cubit.close();
      await notifier.dispose();
    });
  });
}

final class _FakeShowDetailsSeasonsRepository
    implements ShowDetailsSeasonsRepository {
  _FakeShowDetailsSeasonsRepository({
    this.failMarkShowWatched = false,
    this.markShowWatchedCompleter,
  });

  bool failMarkShowWatched;

  final Completer<void>? markShowWatchedCompleter;

  int resolveLocalSeasonsCalls = 0;
  int markShowWatchedCalls = 0;

  final List<int> requestedShowTmdbIds = <int>[];
  final List<String> requestedShowIds = <String>[];

  @override
  Future<ShowDetailsSeasonsBootstrap> resolveLocalSeasons({
    required int showTmdbId,
  }) async {
    resolveLocalSeasonsCalls++;
    requestedShowTmdbIds.add(showTmdbId);

    return const ShowDetailsSeasonsBootstrap(
      showId: 'show-uuid',
      seasons: <ShowDetailsLocalSeason>[],
    );
  }

  @override
  Future<void> markShowWatched({required String showId}) async {
    markShowWatchedCalls++;
    requestedShowIds.add(showId);

    if (failMarkShowWatched) {
      throw const AppException.connection();
    }

    final Completer<void>? completer = markShowWatchedCompleter;

    if (completer != null) {
      await completer.future;
    }
  }

  @override
  Future<List<ShowDetailsSeasonProgress>> getSeasonsProgress({
    required String showId,
  }) {
    throw UnsupportedError('Not used by these tests.');
  }

  @override
  Future<List<ShowDetailsEpisode>> getEpisodes({required String seasonId}) {
    throw UnsupportedError('Not used by these tests.');
  }

  @override
  Future<List<ShowDetailsEpisode>> syncEpisodes({required String seasonId}) {
    throw UnsupportedError('Not used by these tests.');
  }

  @override
  Future<ShowDetailsSeasonProgress> getSeasonProgress({
    required String seasonId,
  }) {
    throw UnsupportedError('Not used by these tests.');
  }

  @override
  Future<int> getPreviousUnwatchedEpisodeCount({required String episodeId}) {
    throw UnsupportedError(
      'getPreviousUnwatchedEpisodeCount is not used by this test repository.',
    );
  }

  @override
  Future<int> markEpisodeWatchedWithPrevious({
    required String episodeId,
    DateTime? watchedAt,
  }) {
    throw UnsupportedError(
      'markEpisodeWatchedWithPrevious is not used by this test repository.',
    );
  }

  @override
  Future<ShowDetailsSeasonProgress> markSeasonWatched({
    required String seasonId,
  }) {
    throw UnsupportedError('Not used by these tests.');
  }

  @override
  Future<List<ShowDetailsEpisodeProgress>> getEpisodeProgress({
    required String seasonId,
  }) {
    throw UnsupportedError('Not used by these tests.');
  }

  @override
  Future<ShowDetailsEpisodeProgress> markEpisodeWatched({
    required String episodeId,
    DateTime? watchedAt,
  }) {
    throw UnsupportedError('Not used by these tests.');
  }

  @override
  Future<ShowDetailsEpisodeProgress> markEpisodeUnwatched({
    required String episodeId,
  }) {
    throw UnsupportedError('Not used by these tests.');
  }

  @override
  Future<List<ShowDetailsEpisodeWatchEvent>> getEpisodeWatchEvents({
    required String episodeId,
  }) {
    throw UnsupportedError('Not used by these tests.');
  }

  @override
  Future<void> deleteEpisodeWatchEvent({
    required String episodeId,
    required String eventId,
  }) {
    throw UnsupportedError('Not used by these tests.');
  }

  @override
  Future<void> deleteAllEpisodeWatchEvents({required String episodeId}) {
    throw UnsupportedError('Not used by these tests.');
  }
}
