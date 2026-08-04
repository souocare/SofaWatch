import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/server/models/server_configuration.dart';
import 'package:sofawatch/core/server/repositories/server_configuration_repository.dart';
import 'package:sofawatch/features/server_setup/domain/services/server_connection_tester.dart';

class AppBootstrapData {
  const AppBootstrapData({
    required this.serverConfigurationRepository,
    required this.apiClient,
    required this.serverConnectionTester,
    required this.initialServerConfiguration,
  });

  final ServerConfigurationRepository serverConfigurationRepository;
  final ApiClient apiClient;
  final ServerConnectionTester serverConnectionTester;
  final ServerConfiguration? initialServerConfiguration;
}
