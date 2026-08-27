import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/admin_users/application/cubit/admin_users_state.dart';
import 'package:sofawatch/features/admin_users/domain/models/admin_user.dart';
import 'package:sofawatch/features/admin_users/domain/repositories/admin_users_repository.dart';

final class AdminUsersCubit extends Cubit<AdminUsersState> {
  AdminUsersCubit({required this._repository})
    : super(const AdminUsersInitial());

  final AdminUsersRepository _repository;

  Future<void> load() async {
    if (state is AdminUsersLoading) {
      return;
    }

    emit(const AdminUsersLoading());

    try {
      final List<AdminUser> users = await _repository.listUsers();

      if (isClosed) {
        return;
      }

      emit(AdminUsersSuccess(users));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(AdminUsersFailure(error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(AdminUsersFailure(AppException.unknown(originalError: error)));
    }
  }

  Future<void> retry() {
    return load();
  }
}
