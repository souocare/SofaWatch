import 'package:sofawatch/features/admin_users/domain/models/password_recovery_link.dart';

final class PasswordRecoveryLinkDto {
  const PasswordRecoveryLinkDto({required this.token, required this.expiresAt});

  factory PasswordRecoveryLinkDto.fromJson(Map<String, dynamic> json) {
    final Object? token = json['token'];
    final Object? expiresAt = json['expires_at'];

    if (token is! String || token.trim().isEmpty) {
      throw const FormatException(
        'Password recovery response contains an invalid token.',
      );
    }

    if (expiresAt is! String) {
      throw const FormatException(
        'Password recovery response contains an invalid expiration.',
      );
    }

    final DateTime? parsedExpiresAt = DateTime.tryParse(expiresAt);

    if (parsedExpiresAt == null) {
      throw const FormatException(
        'Password recovery response contains an invalid expiration.',
      );
    }

    return PasswordRecoveryLinkDto(
      token: token.trim(),
      expiresAt: parsedExpiresAt,
    );
  }

  final String token;
  final DateTime expiresAt;

  PasswordRecoveryLink toDomain() {
    return PasswordRecoveryLink(token: token, expiresAt: expiresAt);
  }
}
