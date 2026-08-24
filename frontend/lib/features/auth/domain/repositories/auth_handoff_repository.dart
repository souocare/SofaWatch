import 'package:sofawatch/features/auth/domain/models/auth_handoff.dart';
import 'package:sofawatch/features/auth/domain/models/auth_session.dart';

abstract interface class AuthHandoffRepository {
  Future<AuthHandoff> create();

  Future<AuthSession> exchange(String token);
}
