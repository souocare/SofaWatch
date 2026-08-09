import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/core/state/remote_state.dart';
import 'package:sofawatch/features/explore/application/cubit/explore_state.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_genre_options.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_collection.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending_window.dart';
import 'package:sofawatch/features/explore/domain/repositories/explore_repository.dart';

class ExploreCubit extends Cubit<ExploreState> {
  ExploreCubit(this._repository) : super(const ExploreState());

  final ExploreRepository _repository;

  Future<void> load() async {
    if (state.today.isLoading ||
        state.week.isLoading ||
        state.genres.isLoading ||
        state.popularShows.isLoading ||
        state.popularMovies.isLoading) {
      return;
    }

    emit(
      state.copyWith(
        today: const RemoteState<ExploreTrending>.loading(),
        week: const RemoteState<ExploreTrending>.loading(),
        genres: const RemoteState<ExploreGenreOptions>.loading(),
        popularShows: const RemoteState<ExploreMediaCollection>.loading(),
        popularMovies: const RemoteState<ExploreMediaCollection>.loading(),
      ),
    );

    try {
      final List<Object> results = await Future.wait<Object>(<Future<Object>>[
        _repository.getTrending(window: ExploreTrendingWindow.day),
        _repository.getTrending(window: ExploreTrendingWindow.week),
        _repository.getGenres(),
        _repository.getPopularShows(),
        _repository.getPopularMovies(),
      ]);

      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          today: RemoteState<ExploreTrending>.success(
            results[0] as ExploreTrending,
          ),
          week: RemoteState<ExploreTrending>.success(
            results[1] as ExploreTrending,
          ),
          genres: RemoteState<ExploreGenreOptions>.success(
            results[2] as ExploreGenreOptions,
          ),
          popularShows: RemoteState<ExploreMediaCollection>.success(
            results[3] as ExploreMediaCollection,
          ),
          popularMovies: RemoteState<ExploreMediaCollection>.success(
            results[4] as ExploreMediaCollection,
          ),
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          today: RemoteState<ExploreTrending>.failure(error),
          week: RemoteState<ExploreTrending>.failure(error),
          genres: RemoteState<ExploreGenreOptions>.failure(error),
          popularShows: RemoteState<ExploreMediaCollection>.failure(error),
          popularMovies: RemoteState<ExploreMediaCollection>.failure(error),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Explore unexpected error: $error');
      debugPrintStack(label: 'Explore stack trace', stackTrace: stackTrace);

      if (isClosed) {
        return;
      }

      final AppException exception = AppException.unknown(originalError: error);

      emit(
        state.copyWith(
          today: RemoteState<ExploreTrending>.failure(exception),
          week: RemoteState<ExploreTrending>.failure(exception),
          genres: RemoteState<ExploreGenreOptions>.failure(exception),
          popularShows: RemoteState<ExploreMediaCollection>.failure(exception),
          popularMovies: RemoteState<ExploreMediaCollection>.failure(exception),
        ),
      );
    }
  }

  void changeWeekFilter(ExploreWeekFilter filter) {
    if (filter == state.weekFilter) {
      return;
    }

    emit(state.copyWith(weekFilter: filter));
  }

  Future<void> changeShowGenre(int? genreId) async {
    if (genreId == state.selectedShowGenreId) {
      return;
    }

    emit(
      state.copyWith(
        selectedShowGenreId: genreId,
        clearSelectedShowGenre: genreId == null,
        popularShows: const RemoteState<ExploreMediaCollection>.loading(),
      ),
    );

    try {
      final ExploreMediaCollection result = await _repository.getPopularShows(
        genreId: genreId,
      );

      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          popularShows: RemoteState<ExploreMediaCollection>.success(result),
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          popularShows: RemoteState<ExploreMediaCollection>.failure(error),
        ),
      );
    } catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          popularShows: RemoteState<ExploreMediaCollection>.failure(
            AppException.unknown(originalError: error),
          ),
        ),
      );
    }
  }

  Future<void> retryPopularShows() async {
    emit(
      state.copyWith(
        popularShows: const RemoteState<ExploreMediaCollection>.loading(),
      ),
    );

    try {
      final ExploreMediaCollection result = await _repository.getPopularShows(
        genreId: state.selectedShowGenreId,
      );

      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          popularShows: RemoteState<ExploreMediaCollection>.success(result),
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          popularShows: RemoteState<ExploreMediaCollection>.failure(error),
        ),
      );
    } catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          popularShows: RemoteState<ExploreMediaCollection>.failure(
            AppException.unknown(originalError: error),
          ),
        ),
      );
    }
  }

  Future<void> retryPopularMovies() async {
    emit(
      state.copyWith(
        popularMovies: const RemoteState<ExploreMediaCollection>.loading(),
      ),
    );

    try {
      final ExploreMediaCollection result = await _repository.getPopularMovies(
        genreId: state.selectedMovieGenreId,
      );

      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          popularMovies: RemoteState<ExploreMediaCollection>.success(result),
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          popularMovies: RemoteState<ExploreMediaCollection>.failure(error),
        ),
      );
    } catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          popularMovies: RemoteState<ExploreMediaCollection>.failure(
            AppException.unknown(originalError: error),
          ),
        ),
      );
    }
  }

  Future<void> changeMovieGenre(int? genreId) async {
    if (genreId == state.selectedMovieGenreId) {
      return;
    }

    emit(
      state.copyWith(
        selectedMovieGenreId: genreId,
        clearSelectedMovieGenre: genreId == null,
        popularMovies: const RemoteState<ExploreMediaCollection>.loading(),
      ),
    );

    try {
      final ExploreMediaCollection result = await _repository.getPopularMovies(
        genreId: genreId,
      );

      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          popularMovies: RemoteState<ExploreMediaCollection>.success(result),
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          popularMovies: RemoteState<ExploreMediaCollection>.failure(error),
        ),
      );
    } catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          popularMovies: RemoteState<ExploreMediaCollection>.failure(
            AppException.unknown(originalError: error),
          ),
        ),
      );
    }
  }

  Future<void> retry() {
    return load();
  }
}
