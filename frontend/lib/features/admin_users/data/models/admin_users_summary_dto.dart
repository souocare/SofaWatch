import 'package:sofawatch/features/admin_users/domain/models/admin_users_summary.dart';

final class AdminUsersSummaryDto {
  const AdminUsersSummaryDto({
    required this.total,
    required this.active,
    required this.admins,
  });

  factory AdminUsersSummaryDto.fromJson(Map<String, dynamic> json) {
    final dynamic total = json['total'];
    final dynamic active = json['active'];
    final dynamic admins = json['admins'];

    if (total is! int ||
        active is! int ||
        admins is! int ||
        total < 0 ||
        active < 0 ||
        admins < 0) {
      throw const FormatException('Users summary contains invalid counts.');
    }

    return AdminUsersSummaryDto(total: total, active: active, admins: admins);
  }

  final int total;
  final int active;
  final int admins;

  AdminUsersSummary toDomain() {
    return AdminUsersSummary(total: total, active: active, admins: admins);
  }
}
