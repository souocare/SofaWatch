import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/application/cubit/library_cubit.dart';
import 'package:sofawatch/features/library/domain/repositories/library_repository.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_cubit.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_genre.dart';
import 'package:sofawatch/features/show_details/domain/repositories/show_details_repository.dart';
import 'package:sofawatch/features/show_details/presentation/pages/show_details_page.dart';

void main() {
  group('ShowDetailsPage', () {
    testWidgets('shows tagline and Library action when tagline is available', (
      WidgetTester tester,
    ) async {
      await _pumpShowDetailsPage(
        tester,
        details: _showDetails(tagline: 'The work is mysterious and important.'),
      );

      expect(
        find.byKey(const ValueKey<String>('show-details-tagline')),
        findsOneWidget,
      );

      expect(
        find.text('The work is mysterious and important.'),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('show-details-library-add')),
        findsOneWidget,
      );
    });

    testWidgets('shows Library action when tagline is missing', (
      WidgetTester tester,
    ) async {
      await _pumpShowDetailsPage(tester, details: _showDetails(tagline: null));

      expect(
        find.byKey(const ValueKey<String>('show-details-tagline')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('show-details-library-add')),
        findsOneWidget,
      );
    });

    testWidgets('shows Library action when tagline is blank', (
      WidgetTester tester,
    ) async {
      await _pumpShowDetailsPage(tester, details: _showDetails(tagline: '   '));

      expect(
        find.byKey(const ValueKey<String>('show-details-tagline')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('show-details-library-add')),
        findsOneWidget,
      );
    });
    testWidgets('shows generic failure and retries successfully', (
      WidgetTester tester,
    ) async {
      final _ControlledShowDetailsRepository repository =
          _ControlledShowDetailsRepository(
            results: <Object>[
              const AppException.connection(),
              _showDetails(tagline: null),
            ],
          );

      final ShowDetailsCubit showDetailsCubit = ShowDetailsCubit(
        repository: repository,
        tmdbId: 95396,
      );

      final LibraryCubit libraryCubit = LibraryCubit(_FakeLibraryRepository());

      addTearDown(showDetailsCubit.close);
      addTearDown(libraryCubit.close);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: <BlocProvider<dynamic>>[
              BlocProvider<ShowDetailsCubit>.value(value: showDetailsCubit),
              BlocProvider<LibraryCubit>.value(value: libraryCubit),
            ],
            child: const ShowDetailsPage(),
          ),
        ),
      );

      await showDetailsCubit.load();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('show-details-failure')),
        findsOneWidget,
      );

      expect(find.text('Could not load this series'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('show-details-retry')),
        findsOneWidget,
      );

      expect(repository.calls, 1);

      await tester.tap(
        find.byKey(const ValueKey<String>('show-details-retry')),
      );

      await tester.pumpAndSettle();

      expect(repository.calls, 2);

      expect(
        find.byKey(const ValueKey<String>('show-details-content')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('show-details-failure')),
        findsNothing,
      );
    });

    testWidgets('shows timeout-specific failure message', (
      WidgetTester tester,
    ) async {
      final _ControlledShowDetailsRepository repository =
          _ControlledShowDetailsRepository(
            results: const <Object>[AppException.connectionTimeout()],
          );

      final ShowDetailsCubit showDetailsCubit = ShowDetailsCubit(
        repository: repository,
        tmdbId: 95396,
      );

      final LibraryCubit libraryCubit = LibraryCubit(_FakeLibraryRepository());

      addTearDown(showDetailsCubit.close);
      addTearDown(libraryCubit.close);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: <BlocProvider<dynamic>>[
              BlocProvider<ShowDetailsCubit>.value(value: showDetailsCubit),
              BlocProvider<LibraryCubit>.value(value: libraryCubit),
            ],
            child: const ShowDetailsPage(),
          ),
        ),
      );

      await showDetailsCubit.load();
      await tester.pumpAndSettle();

      expect(find.text('Loading the series took too long'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('show-details-retry')),
        findsOneWidget,
      );
    });

    testWidgets('shows initial loading state', (WidgetTester tester) async {
      final _PendingShowDetailsRepository repository =
          _PendingShowDetailsRepository();

      final ShowDetailsCubit showDetailsCubit = ShowDetailsCubit(
        repository: repository,
        tmdbId: 95396,
      );

      final LibraryCubit libraryCubit = LibraryCubit(_FakeLibraryRepository());

      addTearDown(showDetailsCubit.close);
      addTearDown(libraryCubit.close);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: <BlocProvider<dynamic>>[
              BlocProvider<ShowDetailsCubit>.value(value: showDetailsCubit),
              BlocProvider<LibraryCubit>.value(value: libraryCubit),
            ],
            child: const ShowDetailsPage(),
          ),
        ),
      );

      final Future<void> loading = showDetailsCubit.load();

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('show-details-loading')),
        findsOneWidget,
      );

      repository.complete(_showDetails(tagline: null));

      await loading;
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('show-details-content')),
        findsOneWidget,
      );
    });

    testWidgets('handles missing optional Show metadata', (
      WidgetTester tester,
    ) async {
      await _pumpShowDetailsPage(tester, details: _minimalShowDetails());

      expect(
        find.byKey(const ValueKey<String>('show-details-content')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('show-details-tagline')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('show-details-genres')),
        findsNothing,
      );

      expect(
        find.text('No overview is available for this series.'),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('show-details-rating')),
        findsNothing,
      );

      expect(find.text('Runtime'), findsNothing);

      expect(find.text('Networks'), findsNothing);

      expect(find.text('Status'), findsNothing);

      expect(find.text('Type'), findsNothing);

      expect(find.text('Language'), findsNothing);

      expect(
        find.byKey(const ValueKey<String>('show-details-seasons-section')),
        findsNothing,
      );
    });
    testWidgets('renders Show Details without overflow on narrow mobile', (
      WidgetTester tester,
    ) async {
      await _setTestViewport(tester, width: 320, height: 700);

      await _pumpShowDetailsPage(
        tester,
        details: _showDetails(tagline: 'The work is mysterious and important.'),
      );

      expect(
        find.byKey(const ValueKey<String>('show-details-content')),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);
    });
    testWidgets('renders Show Details on standard mobile width', (
      WidgetTester tester,
    ) async {
      await _setTestViewport(tester, width: 390, height: 844);

      await _pumpShowDetailsPage(
        tester,
        details: _showDetails(tagline: 'The work is mysterious and important.'),
      );

      expect(
        find.byKey(const ValueKey<String>('show-details-content')),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders Show Details without overflow on desktop', (
      WidgetTester tester,
    ) async {
      await _setTestViewport(tester, width: 1280, height: 900);

      await _pumpShowDetailsPage(
        tester,
        details: _showDetails(tagline: 'The work is mysterious and important.'),
      );

      expect(
        find.byKey(const ValueKey<String>('show-details-content')),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders Show Details without overflow on wide desktop', (
      WidgetTester tester,
    ) async {
      await _setTestViewport(tester, width: 1920, height: 1080);

      await _pumpShowDetailsPage(
        tester,
        details: _showDetails(tagline: 'The work is mysterious and important.'),
      );

      expect(
        find.byKey(const ValueKey<String>('show-details-content')),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _pumpShowDetailsPage(
  WidgetTester tester, {
  required ShowDetails details,
}) async {
  final _FakeShowDetailsRepository showDetailsRepository =
      _FakeShowDetailsRepository(details: details);

  final _FakeLibraryRepository libraryRepository = _FakeLibraryRepository();

  final ShowDetailsCubit showDetailsCubit = ShowDetailsCubit(
    repository: showDetailsRepository,
    tmdbId: details.tmdbId,
  );

  final LibraryCubit libraryCubit = LibraryCubit(libraryRepository);

  await showDetailsCubit.load();

  addTearDown(showDetailsCubit.close);
  addTearDown(libraryCubit.close);

  await tester.pumpWidget(
    MaterialApp(
      home: MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<ShowDetailsCubit>.value(value: showDetailsCubit),
          BlocProvider<LibraryCubit>.value(value: libraryCubit),
        ],
        child: const ShowDetailsPage(),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

ShowDetails _showDetails({required String? tagline}) {
  return ShowDetails(
    tmdbId: 95396,
    title: 'Severance',
    originalTitle: 'Severance',
    overview:
        'Mark leads a team of office workers whose memories have been '
        'surgically divided between work and personal lives.',
    tagline: tagline,
    firstAirDate: DateTime(2022, 2, 18),
    lastAirDate: DateTime(2025, 3, 21),
    posterUrl: null,
    backdropUrl: null,
    homepageUrl: null,
    genres: const <ShowDetailsGenre>[
      ShowDetailsGenre(tmdbId: 18, name: 'Drama'),
    ],
    seasons: const [],
    networks: const [],
    originalLanguage: 'en',
    episodeRunTimes: const <int>[50],
    numberOfSeasons: 2,
    numberOfEpisodes: 19,
    inProduction: true,
    status: 'Returning Series',
    showType: 'Scripted',
    popularity: 100,
    voteAverage: 8.4,
    voteCount: 2000,
  );
}

final class _FakeShowDetailsRepository implements ShowDetailsRepository {
  const _FakeShowDetailsRepository({required this.details});

  final ShowDetails details;

  @override
  Future<ShowDetails> getByTmdbId(int tmdbId, {String? language}) async {
    return details;
  }
}

final class _FakeLibraryRepository implements LibraryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

final class _ControlledShowDetailsRepository implements ShowDetailsRepository {
  _ControlledShowDetailsRepository({required this.results});

  final List<Object> results;

  int calls = 0;

  @override
  Future<ShowDetails> getByTmdbId(int tmdbId, {String? language}) async {
    final Object result = results[calls];

    calls++;

    if (result is AppException) {
      throw result;
    }

    return result as ShowDetails;
  }
}

final class _PendingShowDetailsRepository implements ShowDetailsRepository {
  final Completer<ShowDetails> _completer = Completer<ShowDetails>();

  void complete(ShowDetails details) {
    _completer.complete(details);
  }

  @override
  Future<ShowDetails> getByTmdbId(int tmdbId, {String? language}) {
    return _completer.future;
  }
}

ShowDetails _minimalShowDetails() {
  return const ShowDetails(
    tmdbId: 95396,
    title: 'Severance',
    originalTitle: 'Severance',
    originalLanguage: '',
    numberOfSeasons: 0,
    numberOfEpisodes: 0,
    inProduction: false,
    status: '',
    showType: '',
    popularity: 0,
    voteAverage: 0,
    voteCount: 0,
    genres: <ShowDetailsGenre>[],
    seasons: [],
    networks: [],
    episodeRunTimes: <int>[],
    overview: null,
    tagline: null,
    firstAirDate: null,
    lastAirDate: null,
    posterUrl: null,
    backdropUrl: null,
    homepageUrl: null,
  );
}

Future<void> _setTestViewport(
  WidgetTester tester, {
  required double width,
  required double height,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);

  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
