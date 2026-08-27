import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/application/cubit/login_state.dart';
import 'package:sofawatch/features/auth/domain/models/auth_session.dart';
import 'package:sofawatch/features/auth/domain/repositories/auth_repository.dart';

final class LoginCubit extends Cubit<LoginState> {
  LoginCubit({required this._repository}) : super(const LoginInitial());

  final AuthRepository _repository;

  Future<void> submit({
    required String username,
    required String password,
  }) async {
    if (state is LoginSubmitting) {
      return;
    }

    final String normalizedUsername = username.trim();

    final String? usernameError = normalizedUsername.isEmpty
        ? 'Enter your username or email.'
        : null;

    final String? passwordError = password.isEmpty
        ? 'Enter your password.'
        : null;

    if (usernameError != null || passwordError != null) {
      emit(
        LoginValidationFailure(
          usernameError: usernameError,
          passwordError: passwordError,
        ),
      );

      return;
    }

    emit(const LoginSubmitting());

    try {
      final AuthSession session = await _repository.login(
        username: normalizedUsername,
        password: password,
      );

      if (isClosed) {
        return;
      }

      emit(LoginSuccess(session));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      if (_representsInvalidCredentials(error)) {
        emit(const LoginInvalidCredentials());

        return;
      }

      emit(LoginFailure(error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(LoginFailure(AppException.unknown(originalError: error)));
    }
  }

  void clearFeedback() {
    if (state is LoginSubmitting) {
      return;
    }

    if (state is LoginInitial) {
      return;
    }

    emit(const LoginInitial());
  }

  static bool _representsInvalidCredentials(AppException error) {
    return error.type == AppExceptionType.unauthorized &&
        error.code == 'invalid_credentials';
  }
}
