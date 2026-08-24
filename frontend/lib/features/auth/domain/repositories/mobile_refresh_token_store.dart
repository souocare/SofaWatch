abstract interface class MobileRefreshTokenStore {
  Future<String?> read();

  Future<void> save(String refreshToken);

  Future<void> clear();
}
