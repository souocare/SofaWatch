import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_state.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details.dart';
import 'package:sofawatch/features/show_details/domain/repositories/show_details_repository.dart';

final class ShowDetailsCubit extends Cubit<ShowDetailsState> {
  ShowDetailsCubit({
    required this._repository,
    required int tmdbId,
    this._language,
  }) : _tmdbId = tmdbId,
       super(const ShowDetailsInitial());

  final ShowDetailsRepository _repository;
  final int _tmdbId;
  final String? _language;

  Future<void> load() async {
    emit(const ShowDetailsLoading());

    try {
      final ShowDetails details = await _repository.getByTmdbId(
        _tmdbId,
        language: _language,
      );

      if (isClosed) {
        return;
      }

      emit(ShowDetailsSuccess(details));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(ShowDetailsFailure(error));
    } catch (error) {
      if (isClosed) {
        return;
      }

      emit(ShowDetailsFailure(AppException.unknown(originalError: error)));
    }
  }

  Future<void> retry() {
    return load();
  }
}
