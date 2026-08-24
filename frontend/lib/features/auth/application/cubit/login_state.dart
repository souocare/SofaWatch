import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/domain/models/auth_session.dart';

sealed class LoginState extends Equatable {
  const LoginState();

  bool get isSubmitting => this is LoginSubmitting;

  @override
  List<Object?> get props => const <Object?>[];
}

final class LoginInitial extends LoginState {
  const LoginInitial();
}

final class LoginValidationFailure extends LoginState {
  const LoginValidationFailure({this.usernameError, this.passwordError});

  final String? usernameError;
  final String? passwordError;

  @override
  List<Object?> get props => <Object?>[usernameError, passwordError];
}

final class LoginSubmitting extends LoginState {
  const LoginSubmitting();
}

final class LoginSuccess extends LoginState {
  const LoginSuccess(this.session);

  final AuthSession session;

  @override
  List<Object?> get props => <Object?>[session.accessToken, session.expiresIn];
}

final class LoginInvalidCredentials extends LoginState {
  const LoginInvalidCredentials();
}

final class LoginFailure extends LoginState {
  const LoginFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => <Object?>[error];
}
