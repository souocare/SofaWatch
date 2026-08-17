import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/movies/application/cubit/movies_state.dart';
import 'package:sofawatch/features/movies/application/models/movies_filter.dart';
import 'package:sofawatch/features/movies/application/models/movies_sort.dart';
import 'package:sofawatch/features/movies/domain/models/library_movie.dart';
import 'package:sofawatch/features/movies/domain/repositories/movies_repository.dart';

final class MoviesCubit extends Cubit<MoviesState> {
  MoviesCubit({required this.repository}) : super(const MoviesState());

  final MoviesRepository repository;

  Future<void> load() async {
    if (state.isLoading) {
      return;
    }

    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final List<LibraryMovie> libraryMovies = await repository
          .getLibraryMovies();

      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          libraryMovies: libraryMovies,
          isLoading: false,
          clearError: true,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(state.copyWith(isLoading: false, error: error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          isLoading: false,
          error: AppException.unknown(originalError: error),
        ),
      );
    }
  }

  Future<void> retry() {
    return load();
  }

  Future<void> refresh() async {
    if (state.isRefreshing) {
      return;
    }

    /*
     * Refresh differs from the initial load.
     *
     * Existing Movies remain visible while fresh server-owned data is
     * requested. A refresh failure must therefore not replace usable
     * content with a full-screen error state.
     */
    emit(state.copyWith(isRefreshing: true, clearRefreshError: true));

    try {
      final List<LibraryMovie> libraryMovies = await repository
          .getLibraryMovies();

      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          libraryMovies: libraryMovies,
          isRefreshing: false,
          clearError: true,
          clearRefreshError: true,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(state.copyWith(isRefreshing: false, refreshError: error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          isRefreshing: false,
          refreshError: AppException.unknown(originalError: error),
        ),
      );
    }
  }

  void setSearchQuery(String query) {
    if (query == state.searchQuery) {
      return;
    }

    emit(state.copyWith(searchQuery: query));
  }

  void setFilter(MoviesFilter filter) {
    if (filter == state.filter) {
      return;
    }

    emit(state.copyWith(filter: filter));
  }

  void setSort(MoviesSort sort) {
    if (sort == state.sort) {
      return;
    }

    emit(state.copyWith(sort: sort));
  }

  void clearLocalFilters() {
    if (!state.hasLocalConstraints) {
      return;
    }

    emit(state.copyWith(searchQuery: '', filter: MoviesFilter.all));
  }
}
