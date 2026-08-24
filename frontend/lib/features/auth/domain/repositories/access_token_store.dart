abstract interface class AccessTokenStore {
  String? get token;

  void save(String accessToken);

  void clear();
}
