import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_cubit.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_state.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details.dart';
import 'package:sofawatch/features/show_details/domain/repositories/show_details_repository.dart';

void main() {
  group('ShowDetailsCubit', () {
    test('loads show details by TMDB ID', () async {
      final _FakeShowDetailsRepository repository =
          _FakeShowDetailsRepository();

      final ShowDetailsCubit cubit = ShowDetailsCubit(
        repository: repository,
        tmdbId: 95396,
      );

      final Future<List<ShowDetailsState>> statesFuture = cubit.stream
          .take(2)
          .toList();

      await cubit.load();

      final List<ShowDetailsState> states = await statesFuture;

      expect(states, <ShowDetailsState>[
        const ShowDetailsLoading(),
        const ShowDetailsSuccess(_showDetails),
      ]);

      expect(repository.requestedTmdbId, 95396);

      await cubit.close();
    });

    test('emits failure when the repository fails', () async {
      final _FakeShowDetailsRepository repository = _FakeShowDetailsRepository(
        error: const AppException.connection(),
      );

      final ShowDetailsCubit cubit = ShowDetailsCubit(
        repository: repository,
        tmdbId: 95396,
      );

      final Future<List<ShowDetailsState>> statesFuture = cubit.stream
          .take(2)
          .toList();

      await cubit.load();

      final List<ShowDetailsState> states = await statesFuture;

      expect(states.first, const ShowDetailsLoading());
      expect(states.last, isA<ShowDetailsFailure>());

      await cubit.close();
    });
  });
}

const ShowDetails _showDetails = ShowDetails(
  tmdbId: 95396,
  title: 'Severance',
  originalTitle: 'Severance',
  overview: 'A mysterious workplace thriller.',
  tagline: 'We work for Lumon.',
  genres: <String>['Drama', 'Mystery'],
  originalLanguage: 'en',
  numberOfSeasons: 2,
  numberOfEpisodes: 19,
  inProduction: true,
  status: 'Returning Series',
  voteAverage: 8.4,
  voteCount: 3000,
);

final class _FakeShowDetailsRepository implements ShowDetailsRepository {
  _FakeShowDetailsRepository({this.error});

  final AppException? error;

  int? requestedTmdbId;

  @override
  Future<ShowDetails> getByTmdbId(int tmdbId, {String? language}) async {
    requestedTmdbId = tmdbId;

    final AppException? repositoryError = error;

    if (repositoryError != null) {
      throw repositoryError;
    }

    return _showDetails;
  }
}
