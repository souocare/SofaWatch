import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';

sealed class PasswordRecoveryState extends Equatable {
  const PasswordRecoveryState();

  bool get isSubmitting => this is PasswordRecoverySubmitting;

  @override
  List<Object?> get props => const <Object?>[];
}

final class PasswordRecoveryInitial extends PasswordRecoveryState {
  const PasswordRecoveryInitial();
}

final class PasswordRecoveryValidationFailure extends PasswordRecoveryState {
  const PasswordRecoveryValidationFailure({
    this.newPasswordError,
    this.confirmPasswordError,
  });

  final String? newPasswordError;
  final String? confirmPasswordError;

  @override
  List<Object?> get props => <Object?>[newPasswordError, confirmPasswordError];
}

final class PasswordRecoverySubmitting extends PasswordRecoveryState {
  const PasswordRecoverySubmitting();
}

final class PasswordRecoverySuccess extends PasswordRecoveryState {
  const PasswordRecoverySuccess();
}

final class PasswordRecoveryInvalid extends PasswordRecoveryState {
  const PasswordRecoveryInvalid();
}

final class PasswordRecoveryFailure extends PasswordRecoveryState {
  const PasswordRecoveryFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => <Object?>[error];
}
