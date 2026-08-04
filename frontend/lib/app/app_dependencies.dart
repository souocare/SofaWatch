import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/server/repositories/server_configuration_repository.dart';
import 'package:sofawatch/features/server_setup/domain/services/server_connection_tester.dart';

class AppDependencies extends StatelessWidget {
  const AppDependencies({
    required this.serverConfigurationRepository,
    required this.apiClient,
    required this.serverConnectionTester,
    required this.child,
    super.key,
  });

  final ServerConfigurationRepository serverConfigurationRepository;
  final ApiClient apiClient;
  final ServerConnectionTester serverConnectionTester;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: <RepositoryProvider<Object>>[
        RepositoryProvider<ServerConfigurationRepository>.value(
          value: serverConfigurationRepository,
        ),
        RepositoryProvider<ApiClient>.value(value: apiClient),
        RepositoryProvider<ServerConnectionTester>.value(
          value: serverConnectionTester,
        ),
      ],
      child: child,
    );
  }
}
