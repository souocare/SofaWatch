import 'package:equatable/equatable.dart';

final class AdminUser extends Equatable {
  const AdminUser({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    required this.isActive,
    required this.isLocal,
    required this.isAdmin,
  });

  final String id;
  final String? username;
  final String? email;
  final String displayName;
  final bool isActive;
  final bool isLocal;
  final bool isAdmin;

  @override
  List<Object?> get props => <Object?>[
    id,
    username,
    email,
    displayName,
    isActive,
    isLocal,
    isAdmin,
  ];
}
