import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/episode_details/application/cubit/episode_details_cubit.dart';
import 'package:sofawatch/features/episode_details/domain/models/episode_details.dart';
import 'package:sofawatch/features/episode_details/domain/models/episode_details_episode.dart';
import 'package:sofawatch/features/episode_details/domain/models/episode_details_progress.dart';
import 'package:sofawatch/features/episode_details/domain/models/episode_details_season.dart';
import 'package:sofawatch/features/episode_details/domain/models/episode_details_show.dart';
import 'package:sofawatch/features/episode_details/domain/repositories/episode_details_repository.dart';
import 'package:sofawatch/features/episode_details/presentation/pages/episode_details_page.dart';
import 'package:sofawatch/features/episode_progress/domain/repositories/episode_progress_repository.dart';

void main() {
  group('EpisodeDetailsPage', () {
    testWidgets('shows Mark as watched when Episode is currently unwatched', (
      WidgetTester tester,
    ) async {
      final EpisodeDetailsCubit cubit = EpisodeDetailsCubit(
        repository: _FakeEpisodeDetailsRepository(
          details: _episodeDetails(isWatched: false),
        ),
        progressRepository: _FakeEpisodeProgressRepository(),
        episodeId: 'episode-uuid',
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('episode-details-viewing-status')),
        findsOneWidget,
      );

      expect(find.text('Not watched'), findsOneWidget);
      expect(find.text('Mark as watched'), findsOneWidget);
      expect(find.text('Mark as unwatched'), findsNothing);
    });

    testWidgets('shows Mark as unwatched when Episode is currently watched', (
      WidgetTester tester,
    ) async {
      final EpisodeDetailsCubit cubit = EpisodeDetailsCubit(
        repository: _FakeEpisodeDetailsRepository(
          details: _episodeDetails(isWatched: true, watchCount: 2),
        ),
        progressRepository: _FakeEpisodeProgressRepository(),
        episodeId: 'episode-uuid',
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pumpAndSettle();

      expect(find.text('Watched'), findsOneWidget);
      expect(find.text('Mark as unwatched'), findsOneWidget);
      expect(find.text('Times watched'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('disables watched action and shows progress while updating', (
      WidgetTester tester,
    ) async {
      final _PendingEpisodeProgressRepository progressRepository =
          _PendingEpisodeProgressRepository();

      final EpisodeDetailsCubit cubit = EpisodeDetailsCubit(
        repository: _FakeEpisodeDetailsRepository(
          details: _episodeDetails(isWatched: false),
        ),
        progressRepository: progressRepository,
        episodeId: 'episode-uuid',
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pumpAndSettle();

      final Finder action = find.byKey(
        const ValueKey<String>('episode-details-watched-action'),
      );

      expect(action, findsOneWidget);

      await tester.tap(action);
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey<String>('episode-details-watched-action-progress'),
        ),
        findsOneWidget,
      );

      expect(find.text('Updating…'), findsOneWidget);

      final FilledButton button = tester.widget<FilledButton>(action);

      expect(
        button.onPressed,
        isNull,
        reason: 'Episode mutation must not be triggerable twice.',
      );

      progressRepository.complete();

      await tester.pumpAndSettle();
    });

    testWidgets('keeps Episode Details visible and shows SnackBar on failure', (
      WidgetTester tester,
    ) async {
      final EpisodeDetailsCubit cubit = EpisodeDetailsCubit(
        repository: _FakeEpisodeDetailsRepository(
          details: _episodeDetails(isWatched: false),
        ),
        progressRepository: _FakeEpisodeProgressRepository(
          markWatchedError: const AppException.connection(),
        ),
        episodeId: 'episode-uuid',
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('episode-details-watched-action')),
      );

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('episode-details-content')),
        findsOneWidget,
        reason: 'Mutation failure must not replace Episode Details.',
      );

      expect(
        find.text('Could not mark this episode as watched.'),
        findsOneWidget,
      );
    });

    testWidgets('reflects updated watched state after successful mutation', (
      WidgetTester tester,
    ) async {
      final _ChangingEpisodeDetailsRepository detailsRepository =
          _ChangingEpisodeDetailsRepository();

      final EpisodeDetailsCubit cubit = EpisodeDetailsCubit(
        repository: detailsRepository,
        progressRepository: _FakeEpisodeProgressRepository(),
        episodeId: 'episode-uuid',
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pumpAndSettle();

      expect(find.text('Not watched'), findsOneWidget);
      expect(find.text('Mark as watched'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('episode-details-watched-action')),
      );

      await tester.pumpAndSettle();

      expect(detailsRepository.calls, 2);

      expect(find.text('Watched'), findsOneWidget);
      expect(find.text('Mark as unwatched'), findsOneWidget);
      expect(find.text('Mark as watched'), findsNothing);
    });
    testWidgets('shows Rewatch action when Episode has watch history', (
      WidgetTester tester,
    ) async {
      final EpisodeDetailsCubit cubit = EpisodeDetailsCubit(
        repository: _FakeEpisodeDetailsRepository(
          details: _episodeDetails(isWatched: true, watchCount: 1),
        ),
        progressRepository: _FakeEpisodeProgressRepository(),
        episodeId: 'episode-uuid',
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('episode-details-rewatch-action')),
        findsOneWidget,
      );

      expect(find.text('Watched again'), findsOneWidget);
    });

    testWidgets('does not show Rewatch when Episode has no watch history', (
      WidgetTester tester,
    ) async {
      final EpisodeDetailsCubit cubit = EpisodeDetailsCubit(
        repository: _FakeEpisodeDetailsRepository(
          details: _episodeDetails(isWatched: false, watchCount: 0),
        ),
        progressRepository: _FakeEpisodeProgressRepository(),
        episodeId: 'episode-uuid',
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('episode-details-rewatch-action')),
        findsNothing,
      );
    });

    testWidgets('shows Rewatch progress and disables concurrent actions', (
      WidgetTester tester,
    ) async {
      final _PendingEpisodeProgressRepository progressRepository =
          _PendingEpisodeProgressRepository();

      final EpisodeDetailsCubit cubit = EpisodeDetailsCubit(
        repository: _FakeEpisodeDetailsRepository(
          details: _episodeDetails(isWatched: true, watchCount: 1),
        ),
        progressRepository: progressRepository,
        episodeId: 'episode-uuid',
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pumpAndSettle();

      final Finder rewatchButton = find.byKey(
        const ValueKey<String>('episode-details-rewatch-action'),
      );

      await tester.tap(rewatchButton);
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey<String>('episode-details-rewatch-action-progress'),
        ),
        findsOneWidget,
      );

      expect(find.text('Recording…'), findsOneWidget);

      final TextButton button = tester.widget<TextButton>(rewatchButton);

      expect(button.onPressed, isNull);

      final FilledButton watchedButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey<String>('episode-details-watched-action')),
      );

      expect(
        watchedButton.onPressed,
        isNull,
        reason: 'Watched-state action must be disabled during Rewatch.',
      );

      progressRepository.complete();

      await tester.pumpAndSettle();
    });
    testWidgets('keeps Details visible when Rewatch fails', (
      WidgetTester tester,
    ) async {
      final EpisodeDetailsCubit cubit = EpisodeDetailsCubit(
        repository: _FakeEpisodeDetailsRepository(
          details: _episodeDetails(isWatched: true, watchCount: 1),
        ),
        progressRepository: _FakeEpisodeProgressRepository(
          markWatchedError: const AppException.connection(),
        ),
        episodeId: 'episode-uuid',
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('episode-details-rewatch-action')),
      );

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('episode-details-content')),
        findsOneWidget,
      );

      expect(find.text('Could not record this rewatch.'), findsOneWidget);
    });
    testWidgets('disables Mark as watched when Episode has not aired yet', (
      WidgetTester tester,
    ) async {
      final EpisodeDetailsCubit cubit = EpisodeDetailsCubit(
        repository: _FakeEpisodeDetailsRepository(
          details: _episodeDetails(
            isWatched: false,
            airDate: DateTime.now().add(const Duration(days: 30)),
          ),
        ),
        progressRepository: _FakeEpisodeProgressRepository(),
        episodeId: 'episode-uuid',
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('episode-details-not-aired')),
        findsOneWidget,
      );

      expect(find.text('This episode has not aired yet.'), findsOneWidget);

      expect(find.text('Not available yet'), findsOneWidget);

      final FilledButton button = tester.widget<FilledButton>(
        find.byKey(const ValueKey<String>('episode-details-watched-action')),
      );

      expect(
        button.onPressed,
        isNull,
        reason: 'A future Episode must not be markable as watched.',
      );
    });
    testWidgets('disables Mark as watched when Episode air date is unknown', (
      WidgetTester tester,
    ) async {
      final EpisodeDetailsCubit cubit = EpisodeDetailsCubit(
        repository: _FakeEpisodeDetailsRepository(
          details: _episodeDetails(isWatched: false, airDate: null),
        ),
        progressRepository: _FakeEpisodeProgressRepository(),
        episodeId: 'episode-uuid',
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.text('Air date unknown'), findsOneWidget);

      expect(
        find.text('This episode does not have a known air date yet.'),
        findsOneWidget,
      );

      final FilledButton button = tester.widget<FilledButton>(
        find.byKey(const ValueKey<String>('episode-details-watched-action')),
      );

      expect(button.onPressed, isNull);
    });
    testWidgets(
      'allows marking a future Episode as unwatched when already watched',
      (WidgetTester tester) async {
        final EpisodeDetailsCubit cubit = EpisodeDetailsCubit(
          repository: _FakeEpisodeDetailsRepository(
            details: _episodeDetails(
              isWatched: true,
              watchCount: 1,
              airDate: DateTime.now().add(const Duration(days: 30)),
            ),
          ),
          progressRepository: _FakeEpisodeProgressRepository(),
          episodeId: 'episode-uuid',
        );

        addTearDown(cubit.close);

        await cubit.load();

        await tester.pumpWidget(_buildTestApp(cubit: cubit));
        await tester.pumpAndSettle();

        expect(find.text('Watched'), findsOneWidget);
        expect(find.text('Mark as unwatched'), findsOneWidget);

        final FilledButton button = tester.widget<FilledButton>(
          find.byKey(const ValueKey<String>('episode-details-watched-action')),
        );

        expect(
          button.onPressed,
          isNotNull,
          reason:
              'A currently watched Episode must remain correctable even if '
              'its current air date is in the future.',
        );
      },
    );
    testWidgets('disables Rewatch when Episode has not aired yet', (
      WidgetTester tester,
    ) async {
      final EpisodeDetailsCubit cubit = EpisodeDetailsCubit(
        repository: _FakeEpisodeDetailsRepository(
          details: _episodeDetails(
            isWatched: true,
            watchCount: 2,
            airDate: DateTime.now().add(const Duration(days: 30)),
          ),
        ),
        progressRepository: _FakeEpisodeProgressRepository(),
        episodeId: 'episode-uuid',
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      final Finder rewatchAction = find.byKey(
        const ValueKey<String>('episode-details-rewatch-action'),
      );

      expect(rewatchAction, findsOneWidget);

      final TextButton button = tester.widget<TextButton>(rewatchAction);

      expect(
        button.onPressed,
        isNull,
        reason: 'A future Episode must not allow another viewing event.',
      );
    });
    test('returns true when Episode aired before requested date', () {
      final EpisodeDetailsEpisode episode = EpisodeDetailsEpisode(
        id: 'episode-uuid',
        tmdbId: 1947648,
        episodeNumber: 4,
        title: "Woe's Hollow",
        airDate: DateTime(2026, 8, 14),
        voteAverage: 8.5,
        voteCount: 100,
      );

      expect(episode.isAvailableToWatchOn(DateTime(2026, 8, 15)), isTrue);
    });
  });
}

Widget _buildTestApp({required EpisodeDetailsCubit cubit}) {
  return MaterialApp(
    home: BlocProvider<EpisodeDetailsCubit>.value(
      value: cubit,
      child: const EpisodeDetailsPage(),
    ),
  );
}

const Object _defaultAirDate = Object();

EpisodeDetails _episodeDetails({
  required bool isWatched,
  int watchCount = 0,
  Object? airDate = _defaultAirDate,
}) {
  final DateTime? resolvedAirDate = identical(airDate, _defaultAirDate)
      ? DateTime(2025, 2, 7)
      : airDate as DateTime?;

  return EpisodeDetails(
    episode: EpisodeDetailsEpisode(
      id: 'episode-uuid',
      tmdbId: 1947648,
      episodeNumber: 4,
      title: "Woe's Hollow",
      overview: 'An episode overview.',
      airDate: resolvedAirDate,
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
  _FakeEpisodeDetailsRepository({required this.details});

  final EpisodeDetails details;

  @override
  Future<EpisodeDetails> getById(String episodeId) async {
    return details;
  }
}

final class _ChangingEpisodeDetailsRepository
    implements EpisodeDetailsRepository {
  int calls = 0;

  @override
  Future<EpisodeDetails> getById(String episodeId) async {
    calls++;

    if (calls == 1) {
      return _episodeDetails(isWatched: false);
    }

    return _episodeDetails(isWatched: true, watchCount: 1);
  }
}

final class _FakeEpisodeProgressRepository
    implements EpisodeProgressRepository {
  _FakeEpisodeProgressRepository({this.markWatchedError})
    : markUnwatchedError = null;

  final AppException? markWatchedError;
  final AppException? markUnwatchedError;

  @override
  Future<void> markEpisodeWatched({
    required String episodeId,
    DateTime? watchedAt,
  }) async {
    final AppException? error = markWatchedError;

    if (error != null) {
      throw error;
    }
  }

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) async {
    final AppException? error = markUnwatchedError;

    if (error != null) {
      throw error;
    }
  }
}

final class _PendingEpisodeProgressRepository
    implements EpisodeProgressRepository {
  final Completer<void> _completer = Completer<void>();

  void complete() {
    _completer.complete();
  }

  @override
  Future<void> markEpisodeWatched({
    required String episodeId,
    DateTime? watchedAt,
  }) {
    return _completer.future;
  }

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) async {}
}
