import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/application/cubit/library_cubit.dart';
import 'package:sofawatch/features/library/domain/models/imported_library_media.dart';
import 'package:sofawatch/features/library/domain/models/library_entry.dart';
import 'package:sofawatch/features/library/domain/models/library_media_type.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/library/domain/repositories/library_repository.dart';
import 'package:sofawatch/features/movie_details/application/cubit/movie_details_cubit.dart';
import 'package:sofawatch/features/movie_details/domain/models/movie_details.dart';
import 'package:sofawatch/features/movie_details/domain/repositories/movie_details_repository.dart';
import 'package:sofawatch/features/movie_details/presentation/pages/movie_details_page.dart';

void main() {
  group('MovieDetailsPage', () {
    testWidgets('shows loading state while Movie details are loading', (
      WidgetTester tester,
    ) async {
      final _ControlledMovieDetailsRepository repository =
          _ControlledMovieDetailsRepository();

      final MovieDetailsCubit cubit = MovieDetailsCubit(
        repository: repository,
        tmdbId: 438631,
      );

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      final Future<void> loadFuture = cubit.load();

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('movie-details-loading')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('movie-details-loading-hero')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('movie-details-loading-action')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('movie-details-loading-overview-title'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('movie-details-loading-info-title')),
        findsOneWidget,
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);

      repository.complete(_movieDetails);

      await loadFuture;
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('movie-details-loading')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('movie-details-content')),
        findsOneWidget,
      );

      await cubit.close();
    });

    testWidgets('shows Movie details after loading succeeds', (
      WidgetTester tester,
    ) async {
      final _FakeMovieDetailsRepository repository =
          _FakeMovieDetailsRepository();

      final MovieDetailsCubit cubit = MovieDetailsCubit(
        repository: repository,
        tmdbId: 438631,
      );

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('movie-details-content')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('movie-details-title')),
        findsOneWidget,
      );

      expect(find.text('Dune'), findsOneWidget);

      expect(find.text('Beyond fear, destiny awaits.'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('movie-details-overview')),
        findsOneWidget,
      );

      expect(find.text('Paul Atreides travels to Arrakis.'), findsOneWidget);

      expect(find.text('Science Fiction'), findsOneWidget);

      expect(find.text('Adventure'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('shows failure state when loading fails', (
      WidgetTester tester,
    ) async {
      final _FakeMovieDetailsRepository repository =
          _FakeMovieDetailsRepository(error: const AppException.connection());

      final MovieDetailsCubit cubit = MovieDetailsCubit(
        repository: repository,
        tmdbId: 438631,
      );

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('movie-details-failure')),
        findsOneWidget,
      );

      expect(find.text('Could not load this movie'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('movie-details-retry')),
        findsOneWidget,
      );

      await cubit.close();
    });

    testWidgets('shows timeout-specific failure message', (
      WidgetTester tester,
    ) async {
      final _FakeMovieDetailsRepository repository =
          _FakeMovieDetailsRepository(
            error: const AppException.receiveTimeout(),
          );

      final MovieDetailsCubit cubit = MovieDetailsCubit(
        repository: repository,
        tmdbId: 438631,
      );

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pump();

      expect(find.text('Loading the movie took too long'), findsOneWidget);

      expect(find.text('Please try again.'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('Retry requests the Movie again', (WidgetTester tester) async {
      final _RetryMovieDetailsRepository repository =
          _RetryMovieDetailsRepository();

      final MovieDetailsCubit cubit = MovieDetailsCubit(
        repository: repository,
        tmdbId: 438631,
      );

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('movie-details-failure')),
        findsOneWidget,
      );

      expect(repository.requestCount, 1);

      await tester.tap(
        find.byKey(const ValueKey<String>('movie-details-retry')),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(repository.requestCount, 2);

      expect(
        find.byKey(const ValueKey<String>('movie-details-content')),
        findsOneWidget,
      );

      expect(find.text('Dune'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('shows poster placeholder when Movie has no poster', (
      WidgetTester tester,
    ) async {
      final _FakeMovieDetailsRepository repository =
          _FakeMovieDetailsRepository();

      final MovieDetailsCubit cubit = MovieDetailsCubit(
        repository: repository,
        tmdbId: 438631,
      );

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('movie-details-poster-placeholder')),
        findsOneWidget,
      );

      await cubit.close();
    });

    testWidgets('shows backdrop placeholder when Movie has no backdrop', (
      WidgetTester tester,
    ) async {
      final _FakeMovieDetailsRepository repository =
          _FakeMovieDetailsRepository();

      final MovieDetailsCubit cubit = MovieDetailsCubit(
        repository: repository,
        tmdbId: 438631,
      );

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pump();

      expect(
        find.byKey(
          const ValueKey<String>('movie-details-backdrop-placeholder'),
        ),
        findsOneWidget,
      );

      await cubit.close();
    });

    testWidgets('shows Movie rating and vote count in the Hero', (
      WidgetTester tester,
    ) async {
      final _FakeMovieDetailsRepository repository =
          _FakeMovieDetailsRepository();

      final MovieDetailsCubit cubit = MovieDetailsCubit(
        repository: repository,
        tmdbId: 438631,
      );

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('movie-details-rating')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('movie-details-rating-value')),
        findsOneWidget,
      );

      expect(find.text('7.8'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('movie-details-vote-count')),
        findsOneWidget,
      );

      expect(find.text('13.0K votes'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('shows fallback when Movie overview is missing', (
      WidgetTester tester,
    ) async {
      const MovieDetails movieWithoutOverview = MovieDetails(
        tmdbId: 438631,
        title: 'Dune',
        originalTitle: 'Dune',
        genres: <String>[],
        originalLanguage: 'en',
        runtime: 155,
        status: 'Released',
        voteAverage: 7.8,
        voteCount: 13000,
      );

      final _FakeMovieDetailsRepository repository =
          _FakeMovieDetailsRepository(details: movieWithoutOverview);

      final MovieDetailsCubit cubit = MovieDetailsCubit(
        repository: repository,
        tmdbId: 438631,
      );

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pump();

      expect(
        find.text('No overview is available for this movie.'),
        findsOneWidget,
      );

      await cubit.close();
    });

    testWidgets('hides Genres when Movie has no Genres', (
      WidgetTester tester,
    ) async {
      const MovieDetails movieWithoutGenres = MovieDetails(
        tmdbId: 438631,
        title: 'Dune',
        originalTitle: 'Dune',
        overview: 'Paul Atreides travels to Arrakis.',
        tagline: 'Beyond fear, destiny awaits.',
        genres: <String>[],
        originalLanguage: 'en',
        runtime: 155,
        status: 'Released',
        voteAverage: 7.8,
        voteCount: 13000,
      );

      final _FakeMovieDetailsRepository repository =
          _FakeMovieDetailsRepository(details: movieWithoutGenres);

      final MovieDetailsCubit cubit = MovieDetailsCubit(
        repository: repository,
        tmdbId: 438631,
      );

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('movie-details-genres')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('movie-details-content')),
        findsOneWidget,
      );

      await cubit.close();
    });

    testWidgets('shows Movie release date', (WidgetTester tester) async {
      final _FakeMovieDetailsRepository repository =
          _FakeMovieDetailsRepository();

      final MovieDetailsCubit cubit = MovieDetailsCubit(
        repository: repository,
        tmdbId: 438631,
      );

      expect(_movieDetails.releaseDate, DateTime(2021, 10, 22));

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pump();

      expect(find.text('Movie Info'), findsOneWidget);

      final Finder releaseDateRow = find.byKey(
        const ValueKey<String>('movie-details-release-date'),
      );

      expect(releaseDateRow, findsOneWidget);

      final BuildContext context = tester.element(releaseDateRow);

      final String expectedDate = MaterialLocalizations.of(
        context,
      ).formatMediumDate(DateTime(2021, 10, 22));

      expect(
        find.descendant(of: releaseDateRow, matching: find.text(expectedDate)),
        findsOneWidget,
      );

      await cubit.close();
    });

    testWidgets('shows Unknown when Movie release date is missing', (
      WidgetTester tester,
    ) async {
      const MovieDetails movieWithoutReleaseDate = MovieDetails(
        tmdbId: 438631,
        title: 'Dune',
        originalTitle: 'Dune',
        genres: <String>[],
        originalLanguage: 'en',
        runtime: 155,
        status: 'Released',
        voteAverage: 7.8,
        voteCount: 13000,
      );

      final _FakeMovieDetailsRepository repository =
          _FakeMovieDetailsRepository(details: movieWithoutReleaseDate);

      final MovieDetailsCubit cubit = MovieDetailsCubit(
        repository: repository,
        tmdbId: 438631,
      );

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('movie-details-release-date')),
        findsOneWidget,
      );

      expect(find.text('Unknown'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('shows Movie runtime', (WidgetTester tester) async {
      final _FakeMovieDetailsRepository repository =
          _FakeMovieDetailsRepository();

      final MovieDetailsCubit cubit = MovieDetailsCubit(
        repository: repository,
        tmdbId: 438631,
      );

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pump();

      final Finder runtimeRow = find.byKey(
        const ValueKey<String>('movie-details-runtime'),
      );

      expect(runtimeRow, findsOneWidget);

      expect(
        find.descendant(of: runtimeRow, matching: find.text('2h 35m')),
        findsOneWidget,
      );

      await cubit.close();
    });

    testWidgets('hides Runtime when Movie runtime is missing', (
      WidgetTester tester,
    ) async {
      const MovieDetails movieWithoutRuntime = MovieDetails(
        tmdbId: 438631,
        title: 'Dune',
        originalTitle: 'Dune',
        genres: <String>[],
        originalLanguage: 'en',
        status: 'Released',
        voteAverage: 7.8,
        voteCount: 13000,
      );

      final _FakeMovieDetailsRepository repository =
          _FakeMovieDetailsRepository(details: movieWithoutRuntime);

      final MovieDetailsCubit cubit = MovieDetailsCubit(
        repository: repository,
        tmdbId: 438631,
      );

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('movie-details-runtime')),
        findsNothing,
      );

      await cubit.close();
    });

    testWidgets('hides rating when Movie has no rating', (
      WidgetTester tester,
    ) async {
      const MovieDetails movieWithoutRating = MovieDetails(
        tmdbId: 438631,
        title: 'Dune',
        originalTitle: 'Dune',
        genres: <String>[],
        originalLanguage: 'en',
        runtime: 155,
        status: 'Released',
        voteAverage: 0,
        voteCount: 0,
      );

      final _FakeMovieDetailsRepository repository =
          _FakeMovieDetailsRepository(details: movieWithoutRating);

      final MovieDetailsCubit cubit = MovieDetailsCubit(
        repository: repository,
        tmdbId: 438631,
      );

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('movie-details-rating')),
        findsNothing,
      );

      await cubit.close();
    });

    testWidgets('shows rating without vote count when vote count is zero', (
      WidgetTester tester,
    ) async {
      const MovieDetails movieWithoutVotes = MovieDetails(
        tmdbId: 438631,
        title: 'Dune',
        originalTitle: 'Dune',
        genres: <String>[],
        originalLanguage: 'en',
        status: 'Released',
        voteAverage: 7.8,
        voteCount: 0,
      );

      final _FakeMovieDetailsRepository repository =
          _FakeMovieDetailsRepository(details: movieWithoutVotes);

      final MovieDetailsCubit cubit = MovieDetailsCubit(
        repository: repository,
        tmdbId: 438631,
      );

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('movie-details-rating')),
        findsOneWidget,
      );

      expect(find.text('7.8'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('movie-details-vote-count')),
        findsNothing,
      );

      await cubit.close();
    });

    testWidgets('shows Movie status in Movie Info', (
      WidgetTester tester,
    ) async {
      final _FakeMovieDetailsRepository repository =
          _FakeMovieDetailsRepository();

      final MovieDetailsCubit cubit = MovieDetailsCubit(
        repository: repository,
        tmdbId: 438631,
      );

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pump();

      final Finder statusRow = find.byKey(
        const ValueKey<String>('movie-details-status'),
      );

      expect(statusRow, findsOneWidget);

      expect(
        find.descendant(of: statusRow, matching: find.text('Released')),
        findsOneWidget,
      );

      await cubit.close();
    });

    testWidgets('shows original title when it differs from Movie title', (
      WidgetTester tester,
    ) async {
      const MovieDetails movieWithDifferentOriginalTitle = MovieDetails(
        tmdbId: 129,
        title: 'Spirited Away',
        originalTitle: '千と千尋の神隠し',
        genres: <String>[],
        originalLanguage: 'ja',
        status: 'Released',
        voteAverage: 8.5,
        voteCount: 17000,
      );

      final _FakeMovieDetailsRepository repository =
          _FakeMovieDetailsRepository(details: movieWithDifferentOriginalTitle);

      final MovieDetailsCubit cubit = MovieDetailsCubit(
        repository: repository,
        tmdbId: 129,
      );

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pump();

      final Finder originalTitleRow = find.byKey(
        const ValueKey<String>('movie-details-original-title'),
      );

      expect(originalTitleRow, findsOneWidget);

      expect(
        find.descendant(of: originalTitleRow, matching: find.text('千と千尋の神隠し')),
        findsOneWidget,
      );

      await cubit.close();
    });

    testWidgets(
      'hides original title when it matches the displayed Movie title',
      (WidgetTester tester) async {
        final _FakeMovieDetailsRepository repository =
            _FakeMovieDetailsRepository();

        final MovieDetailsCubit cubit = MovieDetailsCubit(
          repository: repository,
          tmdbId: 438631,
        );

        await cubit.load();

        await tester.pumpWidget(_buildTestApp(cubit: cubit));

        await tester.pump();

        expect(
          find.byKey(const ValueKey<String>('movie-details-original-title')),
          findsNothing,
        );

        await cubit.close();
      },
    );

    testWidgets('shows Movie original language', (WidgetTester tester) async {
      final _FakeMovieDetailsRepository repository =
          _FakeMovieDetailsRepository();

      final MovieDetailsCubit cubit = MovieDetailsCubit(
        repository: repository,
        tmdbId: 438631,
      );

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pump();

      final Finder languageRow = find.byKey(
        const ValueKey<String>('movie-details-original-language'),
      );

      expect(languageRow, findsOneWidget);

      expect(
        find.descendant(of: languageRow, matching: find.text('EN')),
        findsOneWidget,
      );

      await cubit.close();
    });

    testWidgets('hides original language when it is missing', (
      WidgetTester tester,
    ) async {
      const MovieDetails movieWithoutLanguage = MovieDetails(
        tmdbId: 438631,
        title: 'Dune',
        originalTitle: 'Dune',
        genres: <String>[],
        originalLanguage: '',
        status: 'Released',
        voteAverage: 7.8,
        voteCount: 13000,
      );

      final _FakeMovieDetailsRepository repository =
          _FakeMovieDetailsRepository(details: movieWithoutLanguage);

      final MovieDetailsCubit cubit = MovieDetailsCubit(
        repository: repository,
        tmdbId: 438631,
      );

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('movie-details-original-language')),
        findsNothing,
      );

      await cubit.close();
    });

    testWidgets('shows Upcoming for a Movie that has not been released yet', (
      WidgetTester tester,
    ) async {
      final _FakeMovieDetailsRepository repository =
          _FakeMovieDetailsRepository(details: _upcomingMovie);

      final MovieDetailsCubit cubit = MovieDetailsCubit(
        repository: repository,
        tmdbId: 123456,
      );

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pump();

      final Finder subtitle = find.byKey(
        const ValueKey<String>('movie-details-subtitle'),
      );

      expect(subtitle, findsOneWidget);

      final Text subtitleWidget = tester.widget<Text>(subtitle);

      expect(subtitleWidget.data, '2099 • Upcoming');

      final Finder releaseDateRow = find.byKey(
        const ValueKey<String>('movie-details-release-date'),
      );

      expect(releaseDateRow, findsOneWidget);

      await cubit.close();
    });

    testWidgets('hides Movie status when status metadata is missing', (
      WidgetTester tester,
    ) async {
      const MovieDetails movieWithoutStatus = MovieDetails(
        tmdbId: 438631,
        title: 'Dune',
        originalTitle: 'Dune',
        genres: <String>[],
        originalLanguage: 'en',
        status: '',
        voteAverage: 0,
        voteCount: 0,
      );

      final _FakeMovieDetailsRepository repository =
          _FakeMovieDetailsRepository(details: movieWithoutStatus);

      final MovieDetailsCubit cubit = MovieDetailsCubit(
        repository: repository,
        tmdbId: 438631,
      );

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('movie-details-status')),
        findsNothing,
      );

      await cubit.close();
    });

    testWidgets('hides tagline when Movie tagline is missing', (
      WidgetTester tester,
    ) async {
      const MovieDetails movieWithoutTagline = MovieDetails(
        tmdbId: 438631,
        title: 'Dune',
        originalTitle: 'Dune',
        overview: 'Paul Atreides travels to Arrakis.',
        genres: <String>[],
        originalLanguage: 'en',
        status: 'Released',
        voteAverage: 0,
        voteCount: 0,
      );

      final _FakeMovieDetailsRepository repository =
          _FakeMovieDetailsRepository(details: movieWithoutTagline);

      final MovieDetailsCubit cubit = MovieDetailsCubit(
        repository: repository,
        tmdbId: 438631,
      );

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('movie-details-tagline')),
        findsNothing,
      );

      await cubit.close();
    });

    testWidgets('uses image placeholders when Movie image URLs are blank', (
      WidgetTester tester,
    ) async {
      const MovieDetails movieWithBlankImages = MovieDetails(
        tmdbId: 438631,
        title: 'Dune',
        originalTitle: 'Dune',
        posterUrl: '   ',
        backdropUrl: '   ',
        genres: <String>[],
        originalLanguage: 'en',
        status: 'Released',
        voteAverage: 0,
        voteCount: 0,
      );

      final _FakeMovieDetailsRepository repository =
          _FakeMovieDetailsRepository(details: movieWithBlankImages);

      final MovieDetailsCubit cubit = MovieDetailsCubit(
        repository: repository,
        tmdbId: 438631,
      );

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('movie-details-poster-placeholder')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('movie-details-backdrop-placeholder'),
        ),
        findsOneWidget,
      );

      await cubit.close();
    });

    testWidgets('renders Movie Details safely with minimal metadata', (
      WidgetTester tester,
    ) async {
      const MovieDetails minimalMovie = MovieDetails(
        tmdbId: 999999,
        title: 'Unknown Movie',
        originalTitle: '',
        genres: <String>[],
        originalLanguage: '',
        status: '',
        voteAverage: 0,
        voteCount: 0,
      );

      final _FakeMovieDetailsRepository repository =
          _FakeMovieDetailsRepository(details: minimalMovie);

      final MovieDetailsCubit cubit = MovieDetailsCubit(
        repository: repository,
        tmdbId: 999999,
      );

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('movie-details-content')),
        findsOneWidget,
      );

      expect(find.text('Unknown Movie'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('movie-details-poster-placeholder')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('movie-details-backdrop-placeholder'),
        ),
        findsOneWidget,
      );

      expect(
        find.text('No overview is available for this movie.'),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('movie-details-genres')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('movie-details-runtime')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('movie-details-rating')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('movie-details-original-language')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('movie-details-original-title')),
        findsNothing,
      );

      await cubit.close();
    });
    testWidgets('uses mobile Movie Details layout on a narrow viewport', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final _FakeMovieDetailsRepository repository =
          _FakeMovieDetailsRepository();

      final MovieDetailsCubit cubit = MovieDetailsCubit(
        repository: repository,
        tmdbId: 438631,
      );

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pump();

      final Finder hero = find.byKey(
        const ValueKey<String>('movie-details-hero'),
      );

      expect(hero, findsOneWidget);

      expect(tester.getSize(hero).height, 360);

      final Finder poster = find.byKey(
        const ValueKey<String>('movie-details-poster-container'),
      );

      expect(poster, findsOneWidget);

      expect(tester.getSize(poster).width, 112);

      expect(
        find.byKey(const ValueKey<String>('movie-details-content')),
        findsOneWidget,
      );

      await cubit.close();
    });
    testWidgets('uses desktop Movie Details layout on a wide viewport', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final _FakeMovieDetailsRepository repository =
          _FakeMovieDetailsRepository();

      final MovieDetailsCubit cubit = MovieDetailsCubit(
        repository: repository,
        tmdbId: 438631,
      );

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pump();

      final Finder hero = find.byKey(
        const ValueKey<String>('movie-details-hero'),
      );

      expect(hero, findsOneWidget);

      expect(tester.getSize(hero).height, 420);

      final Finder poster = find.byKey(
        const ValueKey<String>('movie-details-poster-container'),
      );

      expect(poster, findsOneWidget);

      expect(tester.getSize(poster).width, 150);

      final Finder bodyContainer = find.byKey(
        const ValueKey<String>('movie-details-body-container'),
      );

      expect(bodyContainer, findsOneWidget);

      expect(tester.getSize(bodyContainer).width, lessThanOrEqualTo(1000));

      await cubit.close();
    });
    testWidgets(
      'switches to desktop Movie Details layout at tablet breakpoint',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(900, 900);
        tester.view.devicePixelRatio = 1;

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final _FakeMovieDetailsRepository repository =
            _FakeMovieDetailsRepository();

        final MovieDetailsCubit cubit = MovieDetailsCubit(
          repository: repository,
          tmdbId: 438631,
        );

        await cubit.load();

        await tester.pumpWidget(_buildTestApp(cubit: cubit));

        await tester.pump();

        expect(
          tester
              .getSize(find.byKey(const ValueKey<String>('movie-details-hero')))
              .height,
          420,
        );

        expect(
          tester
              .getSize(
                find.byKey(
                  const ValueKey<String>('movie-details-poster-container'),
                ),
              )
              .width,
          150,
        );

        await cubit.close();
      },
    );
  });
}

Widget _buildTestApp({required MovieDetailsCubit cubit}) {
  return MaterialApp(
    home: MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<MovieDetailsCubit>.value(value: cubit),
        BlocProvider<LibraryCubit>(
          create: (BuildContext context) {
            return LibraryCubit(_FakeMovieDetailsLibraryRepository());
          },
        ),
      ],
      child: const MovieDetailsPage(),
    ),
  );
}

final MovieDetails _movieDetails = MovieDetails(
  tmdbId: 438631,
  title: 'Dune',
  originalTitle: 'Dune',
  overview: 'Paul Atreides travels to Arrakis.',
  tagline: 'Beyond fear, destiny awaits.',
  releaseDate: DateTime(2021, 10, 22),
  genres: <String>['Science Fiction', 'Adventure'],
  originalLanguage: 'en',
  runtime: 155,
  status: 'Released',
  voteAverage: 7.8,
  voteCount: 13000,
);

const MovieDetails _movieDetailsWithImages = MovieDetails(
  tmdbId: 438631,
  title: 'Dune',
  originalTitle: 'Dune',
  overview: 'Paul Atreides travels to Arrakis.',
  tagline: 'Beyond fear, destiny awaits.',
  posterUrl: 'https://example.com/dune-poster.jpg',
  backdropUrl: 'https://example.com/dune-backdrop.jpg',
  genres: <String>['Science Fiction', 'Adventure'],
  originalLanguage: 'en',
  runtime: 155,
  status: 'Released',
  voteAverage: 7.8,
  voteCount: 13000,
);

final MovieDetails _upcomingMovie = MovieDetails(
  tmdbId: 123456,
  title: 'Future Movie',
  originalTitle: 'Future Movie',
  releaseDate: DateTime(2099, 10, 22),
  genres: const <String>['Science Fiction'],
  originalLanguage: 'en',
  runtime: 120,
  status: 'Post Production',
  voteAverage: 0,
  voteCount: 0,
);

final class _FakeMovieDetailsRepository implements MovieDetailsRepository {
  _FakeMovieDetailsRepository({this.error, MovieDetails? details})
    : details = details ?? _movieDetails;

  final AppException? error;
  final MovieDetails details;

  @override
  Future<MovieDetails> getByTmdbId(int tmdbId, {String? language}) async {
    final AppException? repositoryError = error;

    if (repositoryError != null) {
      throw repositoryError;
    }

    return details;
  }
}

final class _RetryMovieDetailsRepository implements MovieDetailsRepository {
  int requestCount = 0;

  @override
  Future<MovieDetails> getByTmdbId(int tmdbId, {String? language}) async {
    requestCount++;

    if (requestCount == 1) {
      throw const AppException.connection();
    }

    return _movieDetails;
  }
}

final class _ControlledMovieDetailsRepository
    implements MovieDetailsRepository {
  final Completer<MovieDetails> _completer = Completer<MovieDetails>();

  void complete(MovieDetails result) {
    _completer.complete(result);
  }

  @override
  Future<MovieDetails> getByTmdbId(int tmdbId, {String? language}) {
    return _completer.future;
  }
}

final class _FakeMovieDetailsLibraryRepository implements LibraryRepository {
  @override
  Future<ImportedLibraryMedia> importMovieByTmdbId(int tmdbId) async {
    return ImportedLibraryMedia(
      id: 'movie-local-uuid',
      tmdbId: tmdbId,
      mediaType: LibraryMediaType.movie,
    );
  }

  @override
  Future<LibraryEntry?> getMovieEntry(String movieId) async {
    return null;
  }

  @override
  Future<LibraryEntry> updateMovieStatus(
    String movieId,
    LibraryStatus status,
  ) async {
    return LibraryEntry(
      id: 'entry-uuid',
      mediaId: movieId,
      mediaType: LibraryMediaType.movie,
      status: status,
      createdAt: DateTime.utc(2026, 8, 10),
      updatedAt: DateTime.utc(2026, 8, 10),
    );
  }

  @override
  Future<LibraryEntry> addMovie(String movieId) async {
    final DateTime now = DateTime.utc(2026, 8, 10);

    return LibraryEntry(
      id: 'library-entry-uuid',
      mediaId: movieId,
      mediaType: LibraryMediaType.movie,
      status: LibraryStatus.planning,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<void> removeMovie(String movieId) async {}

  @override
  Future<ImportedLibraryMedia> importShowByTmdbId(int tmdbId) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry> addShow(String showId) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeShow(String showId) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry> updateShowStatus(String showId, LibraryStatus status) {
    throw UnimplementedError();
  }
}
