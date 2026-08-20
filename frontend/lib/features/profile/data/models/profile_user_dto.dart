import 'package:sofawatch/features/profile/domain/models/profile_user.dart';

final class ProfileUserDto {
  const ProfileUserDto({
    required this.id,
    required this.displayName,
    required this.isLocal,
    required this.isAdmin,
  });

  factory ProfileUserDto.fromJson(Map<String, dynamic> json) {
    final Object? id = json['id'];
    final Object? displayName = json['display_name'];
    final Object? isLocal = json['is_local'];
    final Object? isAdmin = json['is_admin'];

    if (id is! String || id.trim().isEmpty) {
      throw const FormatException(
        'The current user response contains an invalid id.',
      );
    }

    if (displayName is! String || displayName.trim().isEmpty) {
      throw const FormatException(
        'The current user response contains an invalid display name.',
      );
    }

    if (isLocal is! bool) {
      throw const FormatException(
        'The current user response contains an invalid local-user flag.',
      );
    }

    if (isAdmin is! bool) {
      throw const FormatException(
        'The current user response contains an invalid admin flag.',
      );
    }

    return ProfileUserDto(
      id: id.trim(),
      displayName: displayName.trim(),
      isLocal: isLocal,
      isAdmin: isAdmin,
    );
  }

  final String id;
  final String displayName;
  final bool isLocal;
  final bool isAdmin;

  ProfileUser toDomain() {
    return ProfileUser(
      id: id,
      displayName: displayName,
      isLocal: isLocal,
      isAdmin: isAdmin,
    );
  }
}
