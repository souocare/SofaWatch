import 'package:sofawatch/features/security/domain/models/security_settings.dart';

final class SecuritySettingsDto {
  const SecuritySettingsDto({required this.openRegistration});

  final bool openRegistration;

  factory SecuritySettingsDto.fromJson(Map<String, dynamic> json) {
    final Object? rawOpenRegistration = json['open_registration'];

    if (rawOpenRegistration is! bool) {
      throw const FormatException('Security settings response is invalid.');
    }

    return SecuritySettingsDto(openRegistration: rawOpenRegistration);
  }

  SecuritySettings toDomain() {
    return SecuritySettings(openRegistration: openRegistration);
  }
}
