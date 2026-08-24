import 'package:sofawatch/features/security/domain/models/security_settings.dart';

abstract interface class SecuritySettingsRepository {
  Future<SecuritySettings> getSettings();

  Future<SecuritySettings> updateOpenRegistration({required bool enabled});
}
