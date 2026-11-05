import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/domain/models/auth_session.dart';

sealed class RegistrationState extends Equatable {
  const RegistrationState();

  bool get isSubmitting => this is RegistrationSubmitting;

  @override
  List<Object?> get props => const <Object?>[];
}

final class RegistrationInitial extends RegistrationState {
  const RegistrationInitial();
}

final class RegistrationChecking extends RegistrationState {
  const RegistrationChecking();
}

final class RegistrationOpen extends RegistrationState {
  const RegistrationOpen();
}

final class RegistrationClosed extends RegistrationState {
  const RegistrationClosed();
}

final class RegistrationAvailabilityFailure extends RegistrationState {
  const RegistrationAvailabilityFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => <Object?>[error];
}

final class RegistrationValidationFailure extends RegistrationState {
  const RegistrationValidationFailure({
    this.usernameError,
    this.displayNameError,
    this.emailError,
    this.passwordError,
    this.confirmPasswordError,
  });

  final String? usernameError;
  final String? displayNameError;
  final String? emailError;
  final String? passwordError;
  final String? confirmPasswordError;

  @override
  List<Object?> get props => <Object?>[
    usernameError,
    displayNameError,
    emailError,
    passwordError,
    confirmPasswordError,
  ];
}

final class RegistrationSubmitting extends RegistrationState {
  const RegistrationSubmitting();
}

final class RegistrationSuccess extends RegistrationState {
  const RegistrationSuccess(this.session);

  final AuthSession session;

  @override
  List<Object?> get props => <Object?>[session.accessToken, session.expiresIn];
}

final class RegistrationFailure extends RegistrationState {
  const RegistrationFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => <Object?>[error];
}
