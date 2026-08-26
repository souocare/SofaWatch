import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/admin_users/domain/models/password_recovery_link.dart';

sealed class AdminUserPasswordRecoveryState extends Equatable {
  const AdminUserPasswordRecoveryState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class AdminUserPasswordRecoveryInitial
    extends AdminUserPasswordRecoveryState {
  const AdminUserPasswordRecoveryInitial();
}

final class AdminUserPasswordRecoveryLoading
    extends AdminUserPasswordRecoveryState {
  const AdminUserPasswordRecoveryLoading();
}

final class AdminUserPasswordRecoverySuccess
    extends AdminUserPasswordRecoveryState {
  const AdminUserPasswordRecoverySuccess(this.recovery);

  final PasswordRecoveryLink recovery;

  @override
  List<Object?> get props => <Object?>[recovery];
}

final class AdminUserPasswordRecoveryFailure
    extends AdminUserPasswordRecoveryState {
  const AdminUserPasswordRecoveryFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => <Object?>[error];
}
