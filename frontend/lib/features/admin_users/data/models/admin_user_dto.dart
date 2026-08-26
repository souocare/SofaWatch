import 'package:sofawatch/features/admin_users/domain/models/admin_user.dart';

final class AdminUserDto {
  const AdminUserDto({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    required this.isActive,
    required this.isLocal,
    required this.isAdmin,
  });

  factory AdminUserDto.fromJson(Map<String, dynamic> json) {
    final Object? id = json['id'];
    final Object? username = json['username'];
    final Object? email = json['email'];
    final Object? displayName = json['display_name'];
    final Object? isActive = json['is_active'];
    final Object? isLocal = json['is_local'];
    final Object? isAdmin = json['is_admin'];

    if (id is! String || id.trim().isEmpty) {
      throw const FormatException('User response contains an invalid id.');
    }

    if (username != null && username is! String) {
      throw const FormatException(
        'User response contains an invalid username.',
      );
    }

    if (email != null && email is! String) {
      throw const FormatException('User response contains an invalid email.');
    }

    if (displayName is! String || displayName.trim().isEmpty) {
      throw const FormatException(
        'User response contains an invalid display name.',
      );
    }

    if (isActive is! bool) {
      throw const FormatException(
        'User response contains an invalid active flag.',
      );
    }

    if (isLocal is! bool) {
      throw const FormatException(
        'User response contains an invalid local-user flag.',
      );
    }

    if (isAdmin is! bool) {
      throw const FormatException(
        'User response contains an invalid administrator flag.',
      );
    }

    return AdminUserDto(
      id: id.trim(),
      username: switch (username) {
        final String value when value.trim().isNotEmpty => value.trim(),
        _ => null,
      },
      email: switch (email) {
        final String value when value.trim().isNotEmpty => value.trim(),
        _ => null,
      },
      displayName: displayName.trim(),
      isActive: isActive,
      isLocal: isLocal,
      isAdmin: isAdmin,
    );
  }

  final String id;
  final String? username;
  final String? email;
  final String displayName;
  final bool isActive;
  final bool isLocal;
  final bool isAdmin;

  AdminUser toDomain() {
    return AdminUser(
      id: id,
      username: username,
      email: email,
      displayName: displayName,
      isActive: isActive,
      isLocal: isLocal,
      isAdmin: isAdmin,
    );
  }
}
