import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/features/search/domain/entities/search_media_type.dart';
import 'package:sofawatch/features/search/domain/entities/search_result.dart';
import 'package:sofawatch/features/search/presentation/widgets/search_result_row.dart';

void main() {
  testWidgets('opens the Show preview when a Show result is tapped', (
    WidgetTester tester,
  ) async {
    final GoRouter router = GoRouter(
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) {
            return Scaffold(
              body: SearchResultRow(
                result: _showResult,
                onPressed: () {
                  context.push('/shows/${_showResult.tmdbId}');
                },
              ),
            );
          },
        ),
        GoRoute(
          path: '/shows/:showId',
          builder: (BuildContext context, GoRouterState state) {
            return Text(
              'Show preview ${state.pathParameters['showId']}',
              key: const ValueKey<String>('show-preview'),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.tap(
      find.byKey(const ValueKey<String>('search-result-show-1431')),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('show-preview')), findsOneWidget);

    expect(find.text('Show preview 1431'), findsOneWidget);
  });

  testWidgets('opens the Movie preview when a Movie result is tapped', (
    WidgetTester tester,
  ) async {
    final GoRouter router = GoRouter(
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) {
            return Scaffold(
              body: SearchResultRow(
                result: _movieResult,
                onPressed: () {
                  context.pushNamed(
                    AppRoute.tmdbMovieDetails.name,
                    pathParameters: <String, String>{
                      'tmdbId': _movieResult.tmdbId.toString(),
                    },
                  );
                },
              ),
            );
          },
        ),
        GoRoute(
          name: AppRoute.tmdbMovieDetails.name,
          path: '/movies/tmdb/:tmdbId',
          builder: (BuildContext context, GoRouterState state) {
            return Text(
              'Movie preview ${state.pathParameters['tmdbId']}',
              key: const ValueKey<String>('movie-preview'),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.tap(
      find.byKey(const ValueKey<String>('search-result-movie-438631')),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('movie-preview')), findsOneWidget);

    expect(find.text('Movie preview 438631'), findsOneWidget);
  });
}

const SearchResult _showResult = SearchResult(
  mediaType: SearchMediaType.show,
  tmdbId: 1431,
  title: 'CSI: Crime Scene Investigation',
  originalTitle: 'CSI: Crime Scene Investigation',
  originalLanguage: 'en',
  genreIds: <int>[80, 18, 9648],
  popularity: 120,
  voteAverage: 7.6,
  voteCount: 1200,
);

const SearchResult _movieResult = SearchResult(
  mediaType: SearchMediaType.movie,
  tmdbId: 438631,
  title: 'Dune',
  originalTitle: 'Dune',
  originalLanguage: 'en',
  genreIds: <int>[878, 12],
  popularity: 95.4,
  voteAverage: 7.8,
  voteCount: 13000,
);
