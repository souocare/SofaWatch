import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/shows/application/cubit/shows_state.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';
import 'package:sofawatch/features/shows/domain/repositories/shows_repository.dart';

final class ShowsCubit extends Cubit<ShowsState> {
  ShowsCubit({required ShowsRepository repository})
    : _repository = repository,
      super(const ShowsInitial());

  final ShowsRepository _repository;

  Future<void> load() async {
    emit(const ShowsLoading());

    try {
      final List<LibraryShow> shows = await _repository.getLibraryShows();

      if (isClosed) {
        return;
      }

      emit(ShowsSuccess(shows));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(ShowsFailure(error));
    } catch (error) {
      if (isClosed) {
        return;
      }

      emit(ShowsFailure(AppException.unknown(originalError: error)));
    }
  }

  Future<void> retry() {
    return load();
  }
}
