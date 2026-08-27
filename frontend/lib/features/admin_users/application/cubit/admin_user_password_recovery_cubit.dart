import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/admin_users/application/cubit/admin_user_password_recovery_state.dart';
import 'package:sofawatch/features/admin_users/domain/models/password_recovery_link.dart';
import 'package:sofawatch/features/admin_users/domain/repositories/admin_users_repository.dart';

final class AdminUserPasswordRecoveryCubit
    extends Cubit<AdminUserPasswordRecoveryState> {
  AdminUserPasswordRecoveryCubit({required this._repository})
    : super(const AdminUserPasswordRecoveryInitial());

  final AdminUsersRepository _repository;

  Future<void> start({required String userId}) async {
    if (state is AdminUserPasswordRecoveryLoading) {
      return;
    }

    final String normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      emit(
        AdminUserPasswordRecoveryFailure(
          AppException.unknown(
            originalError: ArgumentError.value(
              userId,
              'userId',
              'User id cannot be empty.',
            ),
          ),
        ),
      );

      return;
    }

    emit(const AdminUserPasswordRecoveryLoading());

    try {
      final PasswordRecoveryLink recovery = await _repository
          .startPasswordRecovery(userId: normalizedUserId);

      if (isClosed) {
        return;
      }

      emit(AdminUserPasswordRecoverySuccess(recovery));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(AdminUserPasswordRecoveryFailure(error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        AdminUserPasswordRecoveryFailure(
          AppException.unknown(originalError: error),
        ),
      );
    }
  }

  void reset() {
    if (state is AdminUserPasswordRecoveryInitial) {
      return;
    }

    emit(const AdminUserPasswordRecoveryInitial());
  }
}
