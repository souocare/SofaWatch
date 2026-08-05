import 'package:sofawatch/app/app_bootstrap_data.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/server/models/server_configuration.dart';

import '../fakes/fake_search_repository.dart';
import '../fakes/fake_server_configuration_repository.dart';
import '../fakes/fake_server_connection_tester.dart';
import '../fixtures/server_configuration_fixture.dart';

AppBootstrapData createTestBootstrapData({
  ServerConfiguration? serverConfiguration,
  bool hasConfiguredServer = true,
  FakeServerConfigurationRepository? serverConfigurationRepository,
  FakeServerConnectionTester? serverConnectionTester,
  FakeSearchRepository? searchRepository,
  ApiClient? apiClient,
}) {
  final ServerConfiguration? resolvedConfiguration = hasConfiguredServer
      ? serverConfiguration ?? createServerConfigurationFixture()
      : null;

  final FakeServerConfigurationRepository resolvedRepository =
      serverConfigurationRepository ??
      FakeServerConfigurationRepository(
        initialConfiguration: resolvedConfiguration,
      );

  final FakeServerConnectionTester resolvedConnectionTester =
      serverConnectionTester ?? FakeServerConnectionTester();

  final FakeSearchRepository resolvedSearchRepository =
      searchRepository ?? FakeSearchRepository();

  final ApiClient resolvedApiClient =
      apiClient ?? ApiClient(baseUrl: resolvedConfiguration?.serverUrl);

  return AppBootstrapData(
    serverConfigurationRepository: resolvedRepository,
    apiClient: resolvedApiClient,
    searchRepository: resolvedSearchRepository,
    serverConnectionTester: resolvedConnectionTester,
    initialServerConfiguration: resolvedConfiguration,
  );
}
