import 'package:sofawatch/features/auth/domain/repositories/access_token_store.dart';

final class InMemoryAccessTokenStore implements AccessTokenStore {
  String? _token;

  @override
  String? get token => _token;

  @override
  void save(String accessToken) {
    final String normalizedAccessToken = accessToken.trim();

    if (normalizedAccessToken.isEmpty) {
      throw ArgumentError.value(
        accessToken,
        'accessToken',
        'Access token cannot be empty.',
      );
    }

    _token = normalizedAccessToken;
  }

  @override
  void clear() {
    _token = null;
  }
}
