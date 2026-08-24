import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_entry_state.dart';
import 'package:sofawatch/features/auth/domain/models/setup_status.dart';
import 'package:sofawatch/features/auth/domain/repositories/setup_status_repository.dart';

final class AuthEntryCubit extends Cubit<AuthEntryState> {
  AuthEntryCubit({required SetupStatusRepository repository})
    : _repository = repository,
      super(const AuthEntryInitial());

  final SetupStatusRepository _repository;

  Future<void> load() async {
    if (state is AuthEntryChecking) {
      return;
    }

    emit(const AuthEntryChecking());

    try {
      final SetupStatus status = await _repository.getStatus();

      if (isClosed) {
        return;
      }

      if (status.setupRequired) {
        emit(const AuthEntrySetupRequired());
        return;
      }

      emit(const AuthEntryLoginRequired());
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(AuthEntryFailure(error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(AuthEntryFailure(AppException.unknown(originalError: error)));
    }
  }

  Future<void> retry() {
    return load();
  }
}
