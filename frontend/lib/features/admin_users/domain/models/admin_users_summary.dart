import 'package:equatable/equatable.dart';

final class AdminUsersSummary extends Equatable {
  const AdminUsersSummary({
    required this.total,
    required this.active,
    required this.admins,
  });

  final int total;
  final int active;
  final int admins;

  @override
  List<Object?> get props => <Object?>[total, active, admins];
}
