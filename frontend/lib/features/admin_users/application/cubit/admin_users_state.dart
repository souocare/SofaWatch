import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/admin_users/domain/models/admin_user.dart';

sealed class AdminUsersState extends Equatable {
  const AdminUsersState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class AdminUsersInitial extends AdminUsersState {
  const AdminUsersInitial();
}

final class AdminUsersLoading extends AdminUsersState {
  const AdminUsersLoading();
}

final class AdminUsersSuccess extends AdminUsersState {
  const AdminUsersSuccess(this.users);

  final List<AdminUser> users;

  @override
  List<Object?> get props => <Object?>[users];
}

final class AdminUsersFailure extends AdminUsersState {
  const AdminUsersFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => <Object?>[error];
}
