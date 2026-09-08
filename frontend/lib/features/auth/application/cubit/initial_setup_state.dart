import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/domain/models/auth_session.dart';

sealed class InitialSetupState extends Equatable {
  const InitialSetupState();

  bool get isSubmitting => this is InitialSetupSubmitting;

  @override
  List<Object?> get props => const <Object?>[];
}

final class InitialSetupInitial extends InitialSetupState {
  const InitialSetupInitial();
}

final class InitialSetupValidationFailure extends InitialSetupState {
  const InitialSetupValidationFailure({
    this.displayNameError,
    this.usernameError,
    this.emailError,
    this.passwordError,
    this.confirmPasswordError,
  });

  final String? displayNameError;
  final String? usernameError;
  final String? emailError;
  final String? passwordError;
  final String? confirmPasswordError;

  @override
  List<Object?> get props => <Object?>[
    displayNameError,
    usernameError,
    emailError,
    passwordError,
    confirmPasswordError,
  ];
}

final class InitialSetupSubmitting extends InitialSetupState {
  const InitialSetupSubmitting();
}

final class InitialSetupSuccess extends InitialSetupState {
  const InitialSetupSuccess(this.session);

  final AuthSession session;

  @override
  List<Object?> get props => <Object?>[session.accessToken, session.expiresIn];
}

final class InitialSetupAlreadyCompleted extends InitialSetupState {
  const InitialSetupAlreadyCompleted();
}

final class InitialSetupFailure extends InitialSetupState {
  const InitialSetupFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => <Object?>[error];
}
