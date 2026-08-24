import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/server/models/server_configuration.dart';
import 'package:sofawatch/core/server/repositories/server_configuration_repository.dart';
import 'package:sofawatch/features/auth/domain/repositories/access_token_store.dart';
import 'package:sofawatch/features/auth/domain/repositories/auth_repository.dart';
import 'package:sofawatch/features/auth/domain/repositories/setup_status_repository.dart';
import 'package:sofawatch/features/search/domain/repositories/search_repository.dart';
import 'package:sofawatch/features/server_setup/domain/services/server_connection_tester.dart';

class AppBootstrapData {
  const AppBootstrapData({
    required this.serverConfigurationRepository,
    required this.apiClient,
    required this.serverConnectionTester,
    required this.initialServerConfiguration,
    required this.searchRepository,
    required this.accessTokenStore,
    required this.authRepository,
    required this.setupStatusRepository,
  });

  final ServerConfigurationRepository serverConfigurationRepository;
  final ApiClient apiClient;
  final ServerConnectionTester serverConnectionTester;
  final ServerConfiguration? initialServerConfiguration;
  final SearchRepository searchRepository;
  final AccessTokenStore accessTokenStore;
  final AuthRepository authRepository;
  final SetupStatusRepository setupStatusRepository;
}
