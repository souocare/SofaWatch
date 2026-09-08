import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/application/cubit/initial_setup_state.dart';
import 'package:sofawatch/features/auth/domain/models/auth_session.dart';
import 'package:sofawatch/features/auth/domain/repositories/auth_repository.dart';

final class InitialSetupCubit extends Cubit<InitialSetupState> {
  InitialSetupCubit({required this._repository})
    : super(const InitialSetupInitial());

  final AuthRepository _repository;

  Future<void> submit({
    required String displayName,
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (state is InitialSetupSubmitting) {
      return;
    }

    final String normalizedDisplayName = displayName.trim();
    final String normalizedUsername = username.trim();
    final String normalizedEmail = email.trim();

    final String? displayNameError = normalizedDisplayName.isEmpty
        ? 'Enter your display name.'
        : null;

    String? usernameError;

    if (normalizedUsername.isEmpty) {
      usernameError = 'Enter a username.';
    } else if (normalizedUsername.length < 3) {
      usernameError = 'Username must contain at least 3 characters.';
    } else if (normalizedUsername.length > 32) {
      usernameError = 'Username cannot exceed 32 characters.';
    } else if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(normalizedUsername)) {
      usernameError =
          'Use only letters, numbers, periods, underscores, or hyphens.';
    }

    String? emailError;

    if (normalizedEmail.isNotEmpty && !_looksLikeEmail(normalizedEmail)) {
      emailError = 'Enter a valid email address.';
    }

    String? passwordError;

    if (password.isEmpty) {
      passwordError = 'Enter a password.';
    } else if (password.length < 8) {
      passwordError = 'Password must contain at least 8 characters.';
    } else if (password.length > 128) {
      passwordError = 'Password cannot exceed 128 characters.';
    }

    String? confirmPasswordError;

    if (confirmPassword.isEmpty) {
      confirmPasswordError = 'Confirm your password.';
    } else if (confirmPassword != password) {
      confirmPasswordError = 'Passwords do not match.';
    }

    if (displayNameError != null ||
        usernameError != null ||
        emailError != null ||
        passwordError != null ||
        confirmPasswordError != null) {
      emit(
        InitialSetupValidationFailure(
          displayNameError: displayNameError,
          usernameError: usernameError,
          emailError: emailError,
          passwordError: passwordError,
          confirmPasswordError: confirmPasswordError,
        ),
      );

      return;
    }

    emit(const InitialSetupSubmitting());

    try {
      final AuthSession session = await _repository.initialSetup(
        username: normalizedUsername,
        displayName: normalizedDisplayName,
        password: password,
        email: normalizedEmail.isEmpty ? null : normalizedEmail,
      );

      if (isClosed) {
        return;
      }

      emit(InitialSetupSuccess(session));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      if (_representsCompletedSetup(error)) {
        emit(const InitialSetupAlreadyCompleted());
        return;
      }

      emit(InitialSetupFailure(error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(InitialSetupFailure(AppException.unknown(originalError: error)));
    }
  }

  void clearFeedback() {
    if (state is InitialSetupSubmitting || state is InitialSetupInitial) {
      return;
    }

    emit(const InitialSetupInitial());
  }

  static bool _representsCompletedSetup(AppException error) {
    return error.type == AppExceptionType.conflict &&
        error.code == 'initial_setup_completed';
  }

  static bool _looksLikeEmail(String value) {
    final int atIndex = value.indexOf('@');

    return atIndex > 0 &&
        atIndex == value.lastIndexOf('@') &&
        atIndex < value.length - 1 &&
        value.substring(atIndex + 1).contains('.');
  }
}
