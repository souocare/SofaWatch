import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/server/repositories/server_configuration_repository.dart';
import 'package:sofawatch/features/auth/domain/repositories/access_token_store.dart';
import 'package:sofawatch/features/auth/domain/repositories/auth_repository.dart';
import 'package:sofawatch/features/search/domain/repositories/search_repository.dart';
import 'package:sofawatch/features/server_setup/domain/services/server_connection_tester.dart';
import 'package:sofawatch/features/auth/domain/repositories/setup_status_repository.dart';

class AppDependencies extends StatelessWidget {
  const AppDependencies({
    required this.serverConfigurationRepository,
    required this.apiClient,
    required this.searchRepository,
    required this.serverConnectionTester,
    required this.accessTokenStore,
    required this.authRepository,
    required this.child,
    required this.setupStatusRepository,
    super.key,
  });

  final ServerConfigurationRepository serverConfigurationRepository;
  final ApiClient apiClient;
  final SearchRepository searchRepository;
  final ServerConnectionTester serverConnectionTester;
  final AccessTokenStore accessTokenStore;
  final AuthRepository authRepository;
  final Widget child;
  final SetupStatusRepository setupStatusRepository;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: <RepositoryProvider<Object>>[
        RepositoryProvider<ServerConfigurationRepository>.value(
          value: serverConfigurationRepository,
        ),
        RepositoryProvider<ApiClient>.value(value: apiClient),
        RepositoryProvider<SearchRepository>.value(value: searchRepository),
        RepositoryProvider<ServerConnectionTester>.value(
          value: serverConnectionTester,
        ),
        RepositoryProvider<AccessTokenStore>.value(value: accessTokenStore),
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<SetupStatusRepository>.value(
          value: setupStatusRepository,
        ),
      ],
      child: child,
    );
  }
}
