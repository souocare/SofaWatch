abstract interface class ServerConnectionTester {
  Future<void> testConnection(Uri serverUrl);
}
