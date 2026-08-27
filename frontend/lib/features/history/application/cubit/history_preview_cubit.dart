import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/core/viewing/viewing_state_change_notifier.dart';
import 'package:sofawatch/features/history/application/cubit/history_preview_state.dart';
import 'package:sofawatch/features/history/domain/models/history_preview.dart';
import 'package:sofawatch/features/history/domain/repositories/history_repository.dart';

final class HistoryPreviewCubit extends Cubit<HistoryPreviewState> {
  HistoryPreviewCubit({
    required this._repository,
    required ViewingStateChangeNotifier viewingStateChangeNotifier,
  }) : super(const HistoryPreviewInitial()) {
    _viewingStateChangeSubscription = viewingStateChangeNotifier.changes.listen(
      (_) {
        unawaited(load());
      },
    );
  }

  final HistoryRepository _repository;

  late final StreamSubscription<void> _viewingStateChangeSubscription;

  Future<void> load() async {
    if (state is HistoryPreviewLoading) {
      return;
    }

    emit(const HistoryPreviewLoading());

    try {
      final HistoryPreview preview = await _repository.getPreview();

      if (isClosed) {
        return;
      }

      emit(HistoryPreviewSuccess(preview));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(HistoryPreviewFailure(error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(HistoryPreviewFailure(AppException.unknown(originalError: error)));
    }
  }

  Future<void> retry() {
    return load();
  }

  @override
  Future<void> close() async {
    await _viewingStateChangeSubscription.cancel();

    return super.close();
  }
}
