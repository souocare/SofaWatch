import 'package:sofawatch/features/auth/domain/models/auth_session.dart';

abstract interface class AuthRepository {
  Future<AuthSession> initialSetup({
    required String username,
    required String displayName,
    required String password,
    String? email,
  });

  Future<AuthSession> login({
    required String username,
    required String password,
  });

  Future<AuthSession?> restore();

  Future<void> logout();

  Future<void> logoutEverywhere();

  Future<void> clearLocalAuthentication();
}
