import 'package:sofawatch/features/admin_users/domain/models/admin_user.dart';
import 'package:sofawatch/features/admin_users/domain/models/password_recovery_link.dart';
import 'package:sofawatch/features/admin_users/domain/models/admin_users_summary.dart';

abstract interface class AdminUsersRepository {
  Future<List<AdminUser>> listUsers();

  Future<AdminUsersSummary> getSummary();

  Future<PasswordRecoveryLink> startPasswordRecovery({required String userId});
}
