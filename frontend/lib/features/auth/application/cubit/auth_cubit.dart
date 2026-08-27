import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_state.dart';
import 'package:sofawatch/features/auth/domain/models/auth_session.dart';
import 'package:sofawatch/features/auth/domain/repositories/auth_repository.dart';

final class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required this._repository}) : super(const AuthInitial());

  final AuthRepository _repository;

  Future<void> restore() async {
    if (state is AuthChecking) {
      return;
    }

    emit(const AuthChecking());

    try {
      final AuthSession? session = await _repository.restore();

      if (isClosed) {
        return;
      }

      if (session == null) {
        emit(const AuthUnauthenticated());
        return;
      }

      emit(AuthAuthenticated(session));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      if (_representsMissingAuthentication(error)) {
        emit(const AuthUnauthenticated());
        return;
      }

      emit(AuthFailure(error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(AuthFailure(AppException.unknown(originalError: error)));
    }
  }

  void authenticated(AuthSession session) {
    if (isClosed) {
      return;
    }

    emit(AuthAuthenticated(session));
  }

  Future<void> retryRestore() {
    return restore();
  }

  Future<void> logout() async {
    if (state is AuthLoggingOut || state is AuthLoggingOutEverywhere) {
      return;
    }

    emit(const AuthLoggingOut());

    try {
      await _repository.logout();
    } on AppException {
      // Local authentication has already been cleared by the repository.
    } on Object {
      // Logout must still complete locally if the remote call fails.
    }

    if (isClosed) {
      return;
    }

    emit(const AuthUnauthenticated());
  }

  Future<void> logoutEverywhere() async {
    if (state is AuthLoggingOut || state is AuthLoggingOutEverywhere) {
      return;
    }

    emit(const AuthLoggingOutEverywhere());

    try {
      await _repository.logoutEverywhere();
    } on AppException {
      /*
     * The repository guarantees local credential cleanup even when
     * revoking the remote sessions fails.
     *
     * The current device must therefore still leave the authenticated
     * state after an explicit "log out everywhere" action.
     */
    } on Object {
      /*
     * Unexpected transport/storage failures must not leave this device
     * authenticated after the user explicitly requested logout.
     */
    }

    if (isClosed) {
      return;
    }

    emit(const AuthUnauthenticated());
  }

  static bool _representsMissingAuthentication(AppException error) {
    if (error.type != AppExceptionType.unauthorized) {
      return false;
    }

    return switch (error.code) {
      'session_required' ||
      'invalid_session' ||
      'invalid_refresh_token' => true,
      _ => false,
    };
  }
}
