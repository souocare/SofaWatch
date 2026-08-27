import 'package:sofawatch/features/auth/domain/models/auth_handoff.dart';

final class AuthHandoffResponseDto {
  const AuthHandoffResponseDto({
    required this.handoffToken,
    required this.expiresIn,
  });

  factory AuthHandoffResponseDto.fromJson(Map<String, dynamic> json) {
    final Object? rawToken = json['handoff_token'];
    final Object? rawExpiresIn = json['expires_in'];

    if (rawToken is! String ||
        rawToken.trim().isEmpty ||
        rawExpiresIn is! int ||
        rawExpiresIn <= 0) {
      throw const FormatException(
        'Authentication handoff response is invalid.',
      );
    }

    return AuthHandoffResponseDto(
      handoffToken: rawToken,
      expiresIn: rawExpiresIn,
    );
  }

  final String handoffToken;
  final int expiresIn;

  AuthHandoff toDomain() {
    return AuthHandoff(
      token: handoffToken,
      expiresIn: Duration(seconds: expiresIn),
    );
  }
}
