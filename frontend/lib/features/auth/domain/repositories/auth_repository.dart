import 'package:sofawatch/features/auth/domain/models/auth_session.dart';

abstract interface class AuthRepository {
  Future<AuthSession> login({
    required String username,
    required String password,
  });

  Future<AuthSession?> restore();

  Future<void> logout();

  Future<void> logoutEverywhere();
}
