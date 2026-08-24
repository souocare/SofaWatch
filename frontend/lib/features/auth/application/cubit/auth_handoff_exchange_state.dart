import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/domain/models/auth_session.dart';

sealed class AuthHandoffExchangeState extends Equatable {
  const AuthHandoffExchangeState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class AuthHandoffExchangeInitial extends AuthHandoffExchangeState {
  const AuthHandoffExchangeInitial();
}

final class AuthHandoffExchangeLoading extends AuthHandoffExchangeState {
  const AuthHandoffExchangeLoading();
}

final class AuthHandoffExchangeSuccess extends AuthHandoffExchangeState {
  const AuthHandoffExchangeSuccess(this.session);

  final AuthSession session;

  @override
  List<Object?> get props => <Object?>[session.accessToken, session.expiresIn];
}

final class AuthHandoffExchangeInvalid extends AuthHandoffExchangeState {
  const AuthHandoffExchangeInvalid();
}

final class AuthHandoffExchangeFailure extends AuthHandoffExchangeState {
  const AuthHandoffExchangeFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => <Object?>[error];
}
