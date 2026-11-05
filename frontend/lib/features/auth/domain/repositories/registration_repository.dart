import 'package:sofawatch/features/auth/domain/models/auth_session.dart';

abstract interface class RegistrationRepository {
  Future<bool> isRegistrationOpen();

  Future<AuthSession> register({
    required String username,
    required String displayName,
    required String password,
    String? email,
  });
}
