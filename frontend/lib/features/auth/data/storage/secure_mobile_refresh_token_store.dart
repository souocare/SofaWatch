import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sofawatch/features/auth/domain/repositories/mobile_refresh_token_store.dart';

class SecureMobileRefreshTokenStore implements MobileRefreshTokenStore {
  SecureMobileRefreshTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _refreshTokenKey =
      'sofawatch.authentication.refresh_token.v1';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() async {
    final String? refreshToken = await _storage.read(key: _refreshTokenKey);

    final String? normalizedRefreshToken = refreshToken?.trim();

    if (normalizedRefreshToken == null || normalizedRefreshToken.isEmpty) {
      return null;
    }

    return normalizedRefreshToken;
  }

  @override
  Future<void> save(String refreshToken) {
    final String normalizedRefreshToken = refreshToken.trim();

    if (normalizedRefreshToken.isEmpty) {
      throw ArgumentError.value(
        refreshToken,
        'refreshToken',
        'Refresh token cannot be empty.',
      );
    }

    return _storage.write(key: _refreshTokenKey, value: normalizedRefreshToken);
  }

  @override
  Future<void> clear() {
    return _storage.delete(key: _refreshTokenKey);
  }
}
