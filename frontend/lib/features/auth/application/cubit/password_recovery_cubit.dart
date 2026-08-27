import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/application/cubit/password_recovery_state.dart';
import 'package:sofawatch/features/auth/domain/repositories/password_recovery_repository.dart';

final class PasswordRecoveryCubit extends Cubit<PasswordRecoveryState> {
  PasswordRecoveryCubit({required this._repository})
    : super(const PasswordRecoveryInitial());

  final PasswordRecoveryRepository _repository;

  Future<void> submit({
    required String? token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (state is PasswordRecoverySubmitting) {
      return;
    }

    final String normalizedToken = token?.trim() ?? '';

    if (normalizedToken.isEmpty) {
      emit(const PasswordRecoveryInvalid());

      return;
    }

    String? newPasswordError;
    String? confirmPasswordError;

    if (newPassword.isEmpty) {
      newPasswordError = 'Enter a new password.';
    } else if (newPassword.length < 8) {
      newPasswordError = 'Password must be at least 8 characters.';
    } else if (newPassword.length > 128) {
      newPasswordError = 'Password must be 128 characters or fewer.';
    }

    if (confirmPassword.isEmpty) {
      confirmPasswordError = 'Confirm your new password.';
    } else if (confirmPassword != newPassword) {
      confirmPasswordError = 'Passwords do not match.';
    }

    if (newPasswordError != null || confirmPasswordError != null) {
      emit(
        PasswordRecoveryValidationFailure(
          newPasswordError: newPasswordError,
          confirmPasswordError: confirmPasswordError,
        ),
      );

      return;
    }

    emit(const PasswordRecoverySubmitting());

    try {
      await _repository.complete(
        token: normalizedToken,
        newPassword: newPassword,
      );

      if (isClosed) {
        return;
      }

      emit(const PasswordRecoverySuccess());
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      if (_representsInvalidRecovery(error)) {
        emit(const PasswordRecoveryInvalid());

        return;
      }

      emit(PasswordRecoveryFailure(error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(PasswordRecoveryFailure(AppException.unknown(originalError: error)));
    }
  }

  void clearFeedback() {
    if (state is PasswordRecoverySubmitting ||
        state is PasswordRecoverySuccess ||
        state is PasswordRecoveryInvalid ||
        state is PasswordRecoveryInitial) {
      return;
    }

    emit(const PasswordRecoveryInitial());
  }

  static bool _representsInvalidRecovery(AppException error) {
    return error.code == 'password_recovery_invalid';
  }
}
