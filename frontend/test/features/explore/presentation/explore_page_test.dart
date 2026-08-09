import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/explore/application/cubit/explore_cubit.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_item.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending.dart';
import 'package:sofawatch/features/explore/domain/repositories/explore_repository.dart';
import 'package:sofawatch/features/explore/presentation/views/explore_view.dart';

void main() {
  group('ExploreView', () {
    testWidgets('shows the Explore discovery header', (
      WidgetTester tester,
    ) async {
      final ExploreCubit cubit = _createLoadedCubit();

      await tester.pumpWidget(_buildTestApp(cubit));

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('explore-page-title')),
        findsOneWidget,
      );

      expect(find.text('Explore'), findsOneWidget);

      expect(find.text('Discover something worth watching.'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('provides a scrollable discovery content area', (
      WidgetTester tester,
    ) async {
      final ExploreCubit cubit = _createLoadedCubit();

      await tester.pumpWidget(_buildTestApp(cubit));

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('explore-scroll-view')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('explore-trending-content')),
        findsOneWidget,
      );

      await cubit.close();
    });

    testWidgets('does not expose a local Search field', (
      WidgetTester tester,
    ) async {
      final ExploreCubit cubit = _createLoadedCubit();

      await tester.pumpWidget(_buildTestApp(cubit));

      await tester.pump();

      expect(find.byType(TextField), findsNothing);

      await cubit.close();
    });
  });
}

Widget _buildTestApp(ExploreCubit cubit) {
  return MaterialApp(
    home: Scaffold(
      body: BlocProvider<ExploreCubit>.value(
        value: cubit,
        child: const ExploreView(),
      ),
    ),
  );
}

ExploreCubit _createLoadedCubit() {
  final ExploreCubit cubit = ExploreCubit(_FakeExploreRepository());

  cubit.load();

  return cubit;
}

final class _FakeExploreRepository implements ExploreRepository {
  @override
  Future<ExploreTrending> getTrending({String? language}) async {
    return ExploreTrending(
      shows: const <ExploreMediaItem>[
        ExploreMediaItem(
          mediaType: ExploreMediaType.show,
          tmdbId: 95396,
          title: 'Severance',
          originalTitle: 'Severance',
          originalLanguage: 'en',
          genreIds: <int>[18],
          popularity: 120,
          voteAverage: 8.4,
          voteCount: 2100,
        ),
      ],
      movies: const <ExploreMediaItem>[
        ExploreMediaItem(
          mediaType: ExploreMediaType.movie,
          tmdbId: 438631,
          title: 'Dune',
          originalTitle: 'Dune',
          originalLanguage: 'en',
          genreIds: <int>[878],
          popularity: 95,
          voteAverage: 7.8,
          voteCount: 13000,
        ),
      ],
    );
  }
}
