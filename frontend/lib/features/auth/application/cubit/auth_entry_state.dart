import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';

sealed class AuthEntryState extends Equatable {
  const AuthEntryState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class AuthEntryInitial extends AuthEntryState {
  const AuthEntryInitial();
}

final class AuthEntryChecking extends AuthEntryState {
  const AuthEntryChecking();
}

final class AuthEntrySetupRequired extends AuthEntryState {
  const AuthEntrySetupRequired();
}

final class AuthEntryLoginRequired extends AuthEntryState {
  const AuthEntryLoginRequired();
}

final class AuthEntryFailure extends AuthEntryState {
  const AuthEntryFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => <Object?>[error];
}
