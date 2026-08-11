import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
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
  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}
