import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/application/cubit/library_collection_state.dart';
import 'package:sofawatch/features/movies/domain/models/library_movie.dart';
import 'package:sofawatch/features/movies/domain/repositories/movies_repository.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';
import 'package:sofawatch/features/shows/domain/repositories/shows_repository.dart';

final class LibraryCollectionCubit extends Cubit<LibraryCollectionState> {
  LibraryCollectionCubit({
    required this._showsRepository,
    required this._moviesRepository,
  }) : super(const LibraryCollectionState());

  final ShowsRepository _showsRepository;
  final MoviesRepository _moviesRepository;

  Future<void> load() async {
    await Future.wait(<Future<void>>[loadShows(), loadMovies()]);
  }

  Future<void> loadShows() async {
    if (state.isLoadingShows) {
      return;
    }

    emit(state.copyWith(isLoadingShows: true, clearShowsError: true));

    try {
      final List<LibraryShow> shows = await _showsRepository.getLibraryShows();

      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          shows: shows,
          isLoadingShows: false,
          clearShowsError: true,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(state.copyWith(isLoadingShows: false, showsError: error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          isLoadingShows: false,
          showsError: AppException.unknown(originalError: error),
        ),
      );
    }
  }

  Future<void> loadMovies() async {
    if (state.isLoadingMovies) {
      return;
    }

    emit(state.copyWith(isLoadingMovies: true, clearMoviesError: true));

    try {
      final List<LibraryMovie> movies = await _moviesRepository
          .getLibraryMovies();

      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          movies: movies,
          isLoadingMovies: false,
          clearMoviesError: true,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(state.copyWith(isLoadingMovies: false, moviesError: error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          isLoadingMovies: false,
          moviesError: AppException.unknown(originalError: error),
        ),
      );
    }
  }

  Future<void> retryShows() {
    return loadShows();
  }

  Future<void> retryMovies() {
    return loadMovies();
  }
}
