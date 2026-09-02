import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/movie_details/application/cubit/movie_details_state.dart';
import 'package:sofawatch/features/movie_details/domain/models/movie_details.dart';
import 'package:sofawatch/features/movie_details/domain/models/movie_details_reference.dart';
import 'package:sofawatch/features/movie_details/domain/repositories/movie_details_repository.dart';

final class MovieDetailsCubit extends Cubit<MovieDetailsState> {
  MovieDetailsCubit({
    required this._repository,
    required this._reference,
    this.language,
  }) : super(const MovieDetailsInitial());

  final MovieDetailsRepository _repository;
  final MovieDetailsReference _reference;
  final String? language;

  Future<void> load() async {
    emit(const MovieDetailsLoading());

    try {
      final MovieDetails details = switch (_reference) {
        LocalMovieDetailsReference(:final movieId) => await _repository.getById(
          movieId,
        ),

        TmdbMovieDetailsReference(:final tmdbId) =>
          await _repository.getByTmdbId(tmdbId, language: language),
      };

      if (isClosed) {
        return;
      }

      emit(MovieDetailsSuccess(details));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(MovieDetailsFailure(error));
    } catch (error) {
      if (isClosed) {
        return;
      }

      emit(MovieDetailsFailure(AppException.unknown(originalError: error)));
    }
  }

  Future<void> retry() {
    return load();
  }
}
