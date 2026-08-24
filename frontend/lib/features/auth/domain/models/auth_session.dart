class AuthSession {
  const AuthSession({required this.accessToken, required this.expiresIn});

  final String accessToken;
  final Duration expiresIn;
}
