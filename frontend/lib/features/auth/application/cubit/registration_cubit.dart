import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/application/cubit/registration_state.dart';
import 'package:sofawatch/features/auth/domain/models/auth_session.dart';
import 'package:sofawatch/features/auth/domain/repositories/registration_repository.dart';

final class RegistrationCubit extends Cubit<RegistrationState> {
  RegistrationCubit({required RegistrationRepository repository})
    : _repository = repository,
      super(const RegistrationInitial());

  final RegistrationRepository _repository;

  bool _registrationAvailable = false;

  static final RegExp _usernamePattern = RegExp(r'^[a-zA-Z0-9._-]+$');

  Future<void> loadAvailability() async {
    if (state is RegistrationChecking || state is RegistrationSubmitting) {
      return;
    }

    _registrationAvailable = false;

    emit(const RegistrationChecking());

    try {
      final bool isOpen = await _repository.isRegistrationOpen();

      if (isClosed) {
        return;
      }

      _registrationAvailable = isOpen;

      emit(isOpen ? const RegistrationOpen() : const RegistrationClosed());
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(RegistrationAvailabilityFailure(error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        RegistrationAvailabilityFailure(
          AppException.unknown(originalError: error),
        ),
      );
    }
  }

  Future<void> submit({
    required String username,
    required String displayName,
    required String password,
    required String confirmPassword,
    String? email,
  }) async {
    if (!_registrationAvailable ||
        state is RegistrationSubmitting ||
        state is RegistrationSuccess) {
      return;
    }

    final String normalizedUsername = username.trim();
    final String normalizedDisplayName = displayName.trim();
    final String? normalizedEmail = email?.trim();

    String? usernameError;
    String? displayNameError;
    String? emailError;
    String? passwordError;
    String? confirmPasswordError;

    if (normalizedUsername.length < 3 ||
        normalizedUsername.length > 32 ||
        !_usernamePattern.hasMatch(normalizedUsername)) {
      usernameError =
          'Use 3–32 letters, numbers, dots, underscores or hyphens.';
    }

    if (normalizedDisplayName.isEmpty || normalizedDisplayName.length > 100) {
      displayNameError = 'Enter a display name (up to 100 characters).';
    }

    if (normalizedEmail != null && normalizedEmail.length > 320) {
      emailError = 'Email cannot exceed 320 characters.';
    }

    if (password.length < 8 || password.length > 128) {
      passwordError = 'Password must contain 8–128 characters.';
    }

    if (confirmPassword != password) {
      confirmPasswordError = 'Passwords do not match.';
    }

    if (usernameError != null ||
        displayNameError != null ||
        emailError != null ||
        passwordError != null ||
        confirmPasswordError != null) {
      emit(
        RegistrationValidationFailure(
          usernameError: usernameError,
          displayNameError: displayNameError,
          emailError: emailError,
          passwordError: passwordError,
          confirmPasswordError: confirmPasswordError,
        ),
      );

      return;
    }

    emit(const RegistrationSubmitting());

    try {
      final AuthSession session = await _repository.register(
        username: normalizedUsername,
        displayName: normalizedDisplayName,
        password: password,
        email: normalizedEmail,
      );

      if (isClosed) {
        return;
      }

      emit(RegistrationSuccess(session));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      if (error.code == 'registration_closed') {
        _registrationAvailable = false;
        emit(const RegistrationClosed());
        return;
      }

      emit(RegistrationFailure(error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(RegistrationFailure(AppException.unknown(originalError: error)));
    }
  }

  void clearFeedback() {
    if (!_registrationAvailable ||
        state is RegistrationSubmitting ||
        state is RegistrationSuccess ||
        state is RegistrationOpen) {
      return;
    }

    emit(const RegistrationOpen());
  }
}
