import 'package:sofawatch/features/profile/domain/models/profile_user.dart';

final class ProfileUserDto {
  const ProfileUserDto({
    required this.id,
    required this.displayName,
    required this.isLocal,
  });

  factory ProfileUserDto.fromJson(Map<String, dynamic> json) {
    final Object? id = json['id'];
    final Object? displayName = json['display_name'];
    final Object? isLocal = json['is_local'];

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

    return ProfileUserDto(
      id: id,
      displayName: displayName.trim(),
      isLocal: isLocal,
    );
  }

  final String id;
  final String displayName;
  final bool isLocal;

  ProfileUser toDomain() {
    return ProfileUser(id: id, displayName: displayName, isLocal: isLocal);
  }
}
