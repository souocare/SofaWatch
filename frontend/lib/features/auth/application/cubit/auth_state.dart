import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/domain/models/auth_session.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthChecking extends AuthState {
  const AuthChecking();
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.session);

  final AuthSession session;

  @override
  List<Object?> get props => <Object?>[session.accessToken, session.expiresIn];
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthFailure extends AuthState {
  const AuthFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => <Object?>[error];
}

final class AuthLoggingOut extends AuthState {
  const AuthLoggingOut();
}

final class AuthLoggingOutEverywhere extends AuthState {
  const AuthLoggingOutEverywhere();
}
