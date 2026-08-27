import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/security/application/cubit/security_settings_state.dart';
import 'package:sofawatch/features/security/domain/models/security_settings.dart';
import 'package:sofawatch/features/security/domain/repositories/security_settings_repository.dart';

final class SecuritySettingsCubit extends Cubit<SecuritySettingsState> {
  SecuritySettingsCubit({required this._repository})
    : super(const SecuritySettingsInitial());

  final SecuritySettingsRepository _repository;

  Future<void> load() async {
    if (state is SecuritySettingsLoading) {
      return;
    }

    emit(const SecuritySettingsLoading());

    try {
      final SecuritySettings settings = await _repository.getSettings();

      if (isClosed) {
        return;
      }

      emit(SecuritySettingsSuccess(settings: settings));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(SecuritySettingsFailure(error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(SecuritySettingsFailure(AppException.unknown(originalError: error)));
    }
  }

  Future<void> retry() {
    return load();
  }

  Future<void> setOpenRegistration(bool enabled) async {
    final SecuritySettingsState currentState = state;

    if (currentState is! SecuritySettingsSuccess ||
        currentState.isUpdating ||
        currentState.settings.openRegistration == enabled) {
      return;
    }

    emit(currentState.copyWith(isUpdating: true, clearUpdateError: true));

    try {
      final SecuritySettings settings = await _repository
          .updateOpenRegistration(enabled: enabled);

      if (isClosed) {
        return;
      }

      emit(SecuritySettingsSuccess(settings: settings));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(currentState.copyWith(isUpdating: false, updateError: error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        currentState.copyWith(
          isUpdating: false,
          updateError: AppException.unknown(originalError: error),
        ),
      );
    }
  }

  void clearUpdateError() {
    final SecuritySettingsState currentState = state;

    if (currentState is! SecuritySettingsSuccess ||
        currentState.updateError == null) {
      return;
    }

    emit(currentState.copyWith(clearUpdateError: true));
  }
}
