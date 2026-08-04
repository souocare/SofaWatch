import 'package:sofawatch/core/server/models/server_configuration.dart';
import 'package:sofawatch/core/server/repositories/server_configuration_repository.dart';

class FakeServerConfigurationRepository
    implements ServerConfigurationRepository {
  FakeServerConfigurationRepository({ServerConfiguration? initialConfiguration})
    : configuration = initialConfiguration;

  ServerConfiguration? configuration;

  int loadCallCount = 0;
  int saveCallCount = 0;
  int clearCallCount = 0;

  Object? loadError;
  Object? saveError;
  Object? clearError;

  @override
  Future<ServerConfiguration?> load() async {
    loadCallCount += 1;

    final Object? error = loadError;

    if (error != null) {
      throw error;
    }

    return configuration;
  }

  @override
  Future<void> save(ServerConfiguration configuration) async {
    saveCallCount += 1;

    final Object? error = saveError;

    if (error != null) {
      throw error;
    }

    this.configuration = configuration;
  }

  @override
  Future<void> clear() async {
    clearCallCount += 1;

    final Object? error = clearError;

    if (error != null) {
      throw error;
    }

    configuration = null;
  }
}
