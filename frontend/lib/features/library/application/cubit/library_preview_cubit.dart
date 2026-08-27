import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/application/cubit/library_preview_state.dart';
import 'package:sofawatch/features/library/domain/models/library_preview.dart';
import 'package:sofawatch/features/library/domain/repositories/library_repository.dart';

final class LibraryPreviewCubit extends Cubit<LibraryPreviewState> {
  LibraryPreviewCubit({required this._repository})
    : super(const LibraryPreviewInitial());

  final LibraryRepository _repository;

  Future<void> load() async {
    if (state is LibraryPreviewLoading) {
      return;
    }

    emit(const LibraryPreviewLoading());

    try {
      final LibraryPreview preview = await _repository.getPreview();

      if (isClosed) {
        return;
      }

      emit(LibraryPreviewSuccess(preview));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(LibraryPreviewFailure(error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(LibraryPreviewFailure(AppException.unknown(originalError: error)));
    }
  }

  Future<void> retry() {
    return load();
  }
}
