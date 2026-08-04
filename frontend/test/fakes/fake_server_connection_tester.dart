import 'package:sofawatch/features/server_setup/domain/services/server_connection_tester.dart';

class FakeServerConnectionTester implements ServerConnectionTester {
  Object? errorToThrow;

  Uri? testedUrl;
  int callCount = 0;

  @override
  Future<void> testConnection(Uri serverUrl) async {
    callCount += 1;
    testedUrl = serverUrl;

    final Object? error = errorToThrow;

    if (error != null) {
      throw error;
    }
  }
}
