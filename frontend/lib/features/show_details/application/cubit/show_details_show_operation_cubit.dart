import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_show_operation.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_seasons_bootstrap.dart';
import 'package:sofawatch/features/show_details/domain/repositories/show_details_seasons_repository.dart';

final class ShowDetailsShowOperationCubit
    extends Cubit<ShowDetailsShowOperation> {
  ShowDetailsShowOperationCubit({
    required this._repository,
    required this._showTmdbId,
  }) : super(const ShowDetailsShowOperation.idle());

  final ShowDetailsSeasonsRepository _repository;
  final int _showTmdbId;

  ShowDetailsSeasonsBootstrap? _bootstrap;

  Future<void> markShowWatched() async {
    if (state.isUpdating) {
      return;
    }

    emit(const ShowDetailsShowOperation.updating());

    try {
      final ShowDetailsSeasonsBootstrap bootstrap =
          _bootstrap ??
          await _repository.resolveLocalSeasons(showTmdbId: _showTmdbId);

      _bootstrap = bootstrap;

      await _repository.markShowWatched(showId: bootstrap.showId);

      if (isClosed) {
        return;
      }

      emit(const ShowDetailsShowOperation.success());
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(ShowDetailsShowOperation.failure(error));
    } catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        ShowDetailsShowOperation.failure(
          AppException.unknown(originalError: error),
        ),
      );
    }
  }

  Future<void> retryMarkShowWatched() async {
    if (!state.hasFailed) {
      return;
    }

    await markShowWatched();
  }

  void reset() {
    if (state.isUpdating) {
      return;
    }

    emit(const ShowDetailsShowOperation.idle());
  }
}
