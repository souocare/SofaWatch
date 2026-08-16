import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/episode_details/application/cubit/episode_details_cubit.dart';
import 'package:sofawatch/features/episode_details/application/cubit/episode_details_operation.dart';
import 'package:sofawatch/features/episode_details/application/cubit/episode_details_state.dart';
import 'package:sofawatch/features/episode_details/domain/models/episode_details.dart';
import 'package:sofawatch/features/episode_details/domain/models/episode_details_episode.dart';
import 'package:sofawatch/features/episode_details/domain/models/episode_details_progress.dart';
import 'package:sofawatch/features/episode_details/domain/models/episode_details_season.dart';
import 'package:sofawatch/features/episode_details/domain/models/episode_details_show.dart';
import 'package:sofawatch/features/episode_details/domain/repositories/episode_details_repository.dart';
import 'package:sofawatch/features/episode_progress/domain/repositories/episode_progress_repository.dart';

void main() {
  group('EpisodeDetailsCubit', () {
    test('loads Episode Details by local Episode ID', () async {
      final _FakeEpisodeDetailsRepository repository =
          _FakeEpisodeDetailsRepository();

      final EpisodeDetailsCubit cubit = EpisodeDetailsCubit(
        repository: repository,
        progressRepository: _FakeEpisodeProgressRepository(),
        episodeId: 'episode-uuid',
      );

      final Future<List<EpisodeDetailsState>> statesFuture = cubit.stream
          .take(2)
          .toList();

      await cubit.load();

      final List<EpisodeDetailsState> states = await statesFuture;

      expect(states, <EpisodeDetailsState>[
        const EpisodeDetailsLoading(),
        EpisodeDetailsSuccess(_episodeDetails()),
      ]);

      expect(repository.requestedEpisodeId, 'episode-uuid');

      await cubit.close();
    });

    test('emits failure when repository fails', () async {
      final _FakeEpisodeDetailsRepository repository =
          _FakeEpisodeDetailsRepository(error: const AppException.connection());

      final EpisodeDetailsCubit cubit = EpisodeDetailsCubit(
        repository: repository,
        progressRepository: _FakeEpisodeProgressRepository(),
        episodeId: 'episode-uuid',
      );

      final Future<List<EpisodeDetailsState>> statesFuture = cubit.stream
          .take(2)
          .toList();

      await cubit.load();

      final List<EpisodeDetailsState> states = await statesFuture;

      expect(states.first, const EpisodeDetailsLoading());
      expect(states.last, isA<EpisodeDetailsFailure>());

      await cubit.close();
    });

    test('maps unexpected errors to unknown failure', () async {
      final EpisodeDetailsCubit cubit = EpisodeDetailsCubit(
        repository: _UnexpectedEpisodeDetailsRepository(),
        progressRepository: _FakeEpisodeProgressRepository(),
        episodeId: 'episode-uuid',
      );

      final Future<List<EpisodeDetailsState>> statesFuture = cubit.stream
          .take(2)
          .toList();

      await cubit.load();

      final List<EpisodeDetailsState> states = await statesFuture;

      final EpisodeDetailsFailure failure =
          states.last as EpisodeDetailsFailure;

      expect(failure.error.type, AppExceptionType.unknown);

      await cubit.close();
    });

    test('retry loads Episode Details again', () async {
      final _FakeEpisodeDetailsRepository repository =
          _FakeEpisodeDetailsRepository();

      final EpisodeDetailsCubit cubit = EpisodeDetailsCubit(
        repository: repository,
        progressRepository: _FakeEpisodeProgressRepository(),
        episodeId: 'episode-uuid',
      );

      await cubit.load();
      await cubit.retry();

      expect(repository.calls, 2);

      await cubit.close();
    });

    test('marks Episode as watched and reloads Details', () async {
      final _FakeEpisodeDetailsRepository detailsRepository =
          _FakeEpisodeDetailsRepository();

      final _FakeEpisodeProgressRepository progressRepository =
          _FakeEpisodeProgressRepository();

      final EpisodeDetailsCubit cubit = EpisodeDetailsCubit(
        repository: detailsRepository,
        progressRepository: progressRepository,
        episodeId: 'episode-uuid',
      );

      await cubit.load();

      expect(detailsRepository.calls, 1);

      await cubit.markWatched();

      expect(progressRepository.markWatchedCalls, 1);
      expect(progressRepository.markedWatchedEpisodeId, 'episode-uuid');

      expect(
        detailsRepository.calls,
        2,
        reason: 'Episode Details must reload after a successful mutation.',
      );

      expect(cubit.state, EpisodeDetailsSuccess(_episodeDetails()));

      await cubit.close();
    });

    test('marks Episode as unwatched and reloads Details', () async {
      final _FakeEpisodeDetailsRepository detailsRepository =
          _FakeEpisodeDetailsRepository();

      final _FakeEpisodeProgressRepository progressRepository =
          _FakeEpisodeProgressRepository();

      final EpisodeDetailsCubit cubit = EpisodeDetailsCubit(
        repository: detailsRepository,
        progressRepository: progressRepository,
        episodeId: 'episode-uuid',
      );

      await cubit.load();

      await cubit.markUnwatched();

      expect(progressRepository.markUnwatchedCalls, 1);
      expect(progressRepository.markedUnwatchedEpisodeId, 'episode-uuid');

      expect(detailsRepository.calls, 2);

      expect(cubit.state, EpisodeDetailsSuccess(_episodeDetails()));

      await cubit.close();
    });

    test('preserves Details when marking watched fails', () async {
      const AppException expectedError = AppException.connection();

      final _FakeEpisodeProgressRepository progressRepository =
          _FakeEpisodeProgressRepository(markWatchedError: expectedError);

      final EpisodeDetailsCubit cubit = EpisodeDetailsCubit(
        repository: _FakeEpisodeDetailsRepository(),
        progressRepository: progressRepository,
        episodeId: 'episode-uuid',
      );

      await cubit.load();
      await cubit.markWatched();

      final EpisodeDetailsSuccess state = cubit.state as EpisodeDetailsSuccess;

      expect(state.details, _episodeDetails());
      expect(state.operation.hasFailed, isTrue);
      expect(state.operation.error, expectedError);
      expect(state.operation.intent, EpisodeDetailsOperationIntent.markWatched);

      await cubit.close();
    });

    test('preserves Details when marking unwatched fails', () async {
      const AppException expectedError = AppException.connection();

      final _FakeEpisodeProgressRepository progressRepository =
          _FakeEpisodeProgressRepository(markUnwatchedError: expectedError);

      final EpisodeDetailsCubit cubit = EpisodeDetailsCubit(
        repository: _FakeEpisodeDetailsRepository(),
        progressRepository: progressRepository,
        episodeId: 'episode-uuid',
      );

      await cubit.load();
      await cubit.markUnwatched();

      final EpisodeDetailsSuccess state = cubit.state as EpisodeDetailsSuccess;

      expect(state.details, _episodeDetails());
      expect(state.operation.hasFailed, isTrue);
      expect(state.operation.error, expectedError);
      expect(
        state.operation.intent,
        EpisodeDetailsOperationIntent.markUnwatched,
      );

      await cubit.close();
    });

    test(
      'ignores duplicate mutation while another operation is running',
      () async {
        final _PendingEpisodeProgressRepository progressRepository =
            _PendingEpisodeProgressRepository();

        final EpisodeDetailsCubit cubit = EpisodeDetailsCubit(
          repository: _FakeEpisodeDetailsRepository(),
          progressRepository: progressRepository,
          episodeId: 'episode-uuid',
        );

        await cubit.load();

        final Future<void> firstOperation = cubit.markWatched();

        await Future<void>.delayed(Duration.zero);

        expect(
          (cubit.state as EpisodeDetailsSuccess).operation.isUpdating,
          isTrue,
        );

        await cubit.markUnwatched();

        expect(progressRepository.markWatchedCalls, 1);

        expect(
          progressRepository.markUnwatchedCalls,
          0,
          reason:
              'A second Episode mutation must be ignored while one is running.',
        );

        progressRepository.complete();

        await firstOperation;

        expect(
          (cubit.state as EpisodeDetailsSuccess).operation.isUpdating,
          isFalse,
        );

        await cubit.close();
      },
    );

    test(
      'rewatch records another viewing and reloads Episode Details',
      () async {
        final _ChangingEpisodeDetailsRepository detailsRepository =
            _ChangingEpisodeDetailsRepository();

        final _RecordingEpisodeProgressRepository progressRepository =
            _RecordingEpisodeProgressRepository();

        final EpisodeDetailsCubit cubit = EpisodeDetailsCubit(
          repository: detailsRepository,
          progressRepository: progressRepository,
          episodeId: 'episode-uuid',
        );

        await cubit.load();

        expect(
          (cubit.state as EpisodeDetailsSuccess).details.progress.watchCount,
          1,
        );

        await cubit.rewatch();

        expect(progressRepository.markWatchedCalls, 1);
        expect(progressRepository.lastEpisodeId, 'episode-uuid');

        expect(
          detailsRepository.calls,
          2,
          reason: 'Episode Details must reload after recording a Rewatch.',
        );

        final EpisodeDetailsSuccess state =
            cubit.state as EpisodeDetailsSuccess;

        expect(state.details.progress.watchCount, 2);
        expect(state.details.progress.isWatched, isTrue);
        expect(state.operation.isUpdating, isFalse);

        await cubit.close();
      },
    );

    test('rewatch does nothing when Episode has no watch history', () async {
      final _FakeEpisodeDetailsRepository detailsRepository =
          _FakeEpisodeDetailsRepository(
            details: _episodeDetails(isWatched: false, watchCount: 0),
          );

      final _RecordingEpisodeProgressRepository progressRepository =
          _RecordingEpisodeProgressRepository();

      final EpisodeDetailsCubit cubit = EpisodeDetailsCubit(
        repository: detailsRepository,
        progressRepository: progressRepository,
        episodeId: 'episode-uuid',
      );

      await cubit.load();
      await cubit.rewatch();

      expect(progressRepository.markWatchedCalls, 0);

      final EpisodeDetailsSuccess state = cubit.state as EpisodeDetailsSuccess;

      expect(state.details.progress.watchCount, 0);
      expect(state.details.progress.isWatched, isFalse);

      expect(state.operation, const EpisodeDetailsOperation.idle());

      await cubit.close();
    });

    test(
      'rewatch exposes failure without discarding Episode Details',
      () async {
        final _FakeEpisodeDetailsRepository detailsRepository =
            _FakeEpisodeDetailsRepository(
              details: _episodeDetails(isWatched: true, watchCount: 1),
            );

        final _RecordingEpisodeProgressRepository progressRepository =
            _RecordingEpisodeProgressRepository(
              markWatchedError: const AppException.connection(),
            );

        final EpisodeDetailsCubit cubit = EpisodeDetailsCubit(
          repository: detailsRepository,
          progressRepository: progressRepository,
          episodeId: 'episode-uuid',
        );

        await cubit.load();
        await cubit.rewatch();

        final EpisodeDetailsSuccess state =
            cubit.state as EpisodeDetailsSuccess;

        expect(state.details, _episodeDetails(isWatched: true, watchCount: 1));

        expect(state.operation.hasFailed, isTrue);

        expect(state.operation.intent, EpisodeDetailsOperationIntent.rewatch);

        expect(state.operation.error?.type, AppExceptionType.connection);

        /*
         * Failed mutation must not cause a Details reload.
         */
        expect(detailsRepository.calls, 1);

        await cubit.close();
      },
    );
  });
}

EpisodeDetails _episodeDetails({bool isWatched = true, int watchCount = 2}) {
  return EpisodeDetails(
    episode: const EpisodeDetailsEpisode(
      id: 'episode-uuid',
      tmdbId: 1947648,
      episodeNumber: 4,
      title: "Woe's Hollow",
      overview: 'An episode overview.',
      runtime: 52,
      voteAverage: 8.5,
      voteCount: 100,
    ),
    season: const EpisodeDetailsSeason(
      id: 'season-uuid',
      seasonNumber: 2,
      title: 'Season 2',
    ),
    show: const EpisodeDetailsShow(
      id: 'show-uuid',
      tmdbId: 95396,
      title: 'Severance',
      originalTitle: 'Severance',
      status: 'Returning Series',
      voteAverage: 8.4,
    ),
    progress: EpisodeDetailsProgress(
      isWatched: isWatched,
      watchCount: watchCount,
    ),
  );
}

final class _FakeEpisodeDetailsRepository implements EpisodeDetailsRepository {
  _FakeEpisodeDetailsRepository({this.error, EpisodeDetails? details})
    : _details = details ?? _episodeDetails();

  final AppException? error;
  final EpisodeDetails _details;

  String? requestedEpisodeId;
  int calls = 0;

  @override
  Future<EpisodeDetails> getById(String episodeId) async {
    calls++;
    requestedEpisodeId = episodeId;

    final AppException? repositoryError = error;

    if (repositoryError != null) {
      throw repositoryError;
    }

    return _details;
  }
}

final class _UnexpectedEpisodeDetailsRepository
    implements EpisodeDetailsRepository {
  @override
  Future<EpisodeDetails> getById(String episodeId) {
    throw StateError('boom');
  }
}

final class _FakeEpisodeProgressRepository
    implements EpisodeProgressRepository {
  _FakeEpisodeProgressRepository({
    this.markWatchedError,
    this.markUnwatchedError,
  });

  final AppException? markWatchedError;
  final AppException? markUnwatchedError;

  int markWatchedCalls = 0;
  int markUnwatchedCalls = 0;

  String? markedWatchedEpisodeId;
  String? markedUnwatchedEpisodeId;

  @override
  Future<void> markEpisodeWatched({
    required String episodeId,
    DateTime? watchedAt,
  }) async {
    markWatchedCalls++;
    markedWatchedEpisodeId = episodeId;

    final AppException? error = markWatchedError;

    if (error != null) {
      throw error;
    }
  }

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) async {
    markUnwatchedCalls++;
    markedUnwatchedEpisodeId = episodeId;

    final AppException? error = markUnwatchedError;

    if (error != null) {
      throw error;
    }
  }
}

final class _PendingEpisodeProgressRepository
    implements EpisodeProgressRepository {
  final Completer<void> _completer = Completer<void>();

  int markWatchedCalls = 0;
  int markUnwatchedCalls = 0;

  void complete() {
    if (!_completer.isCompleted) {
      _completer.complete();
    }
  }

  @override
  Future<void> markEpisodeWatched({
    required String episodeId,
    DateTime? watchedAt,
  }) {
    markWatchedCalls++;

    return _completer.future;
  }

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) async {
    markUnwatchedCalls++;
  }
}

final class _RecordingEpisodeProgressRepository
    implements EpisodeProgressRepository {
  _RecordingEpisodeProgressRepository({this.markWatchedError});

  final AppException? markWatchedError;

  int markWatchedCalls = 0;

  String? lastEpisodeId;

  @override
  Future<void> markEpisodeWatched({
    required String episodeId,
    DateTime? watchedAt,
  }) async {
    markWatchedCalls++;
    lastEpisodeId = episodeId;

    final AppException? error = markWatchedError;

    if (error != null) {
      throw error;
    }
  }

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) async {}
}

final class _ChangingEpisodeDetailsRepository
    implements EpisodeDetailsRepository {
  int calls = 0;

  @override
  Future<EpisodeDetails> getById(String episodeId) async {
    calls++;

    if (calls == 1) {
      return _episodeDetails(isWatched: true, watchCount: 1);
    }

    return _episodeDetails(isWatched: true, watchCount: 2);
  }
}
