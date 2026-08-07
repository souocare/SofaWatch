import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sofawatch/app/app_bootstrap_data.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/logging/app_bloc_observer.dart';
import 'package:sofawatch/core/server/models/server_configuration.dart';
import 'package:sofawatch/core/server/repositories/server_configuration_repository.dart';
import 'package:sofawatch/core/server/repositories/shared_preferences_server_configuration_repository.dart';
import 'package:sofawatch/core/storage/key_value_store.dart';
import 'package:sofawatch/core/storage/shared_preferences_key_value_store.dart';
import 'package:sofawatch/features/search/data/repositories/api_search_repository.dart';
import 'package:sofawatch/features/server_setup/data/services/api_server_connection_tester.dart';
import 'package:sofawatch/features/server_setup/domain/services/server_connection_tester.dart';

Future<void> bootstrap(
  FutureOr<Widget> Function(AppBootstrapData data) builder,
) async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  usePathUrlStrategy();

  Bloc.observer = const AppBlocObserver();

  final KeyValueStore storage = SharedPreferencesKeyValueStore();

  final ServerConfigurationRepository serverConfigurationRepository =
      SharedPreferencesServerConfigurationRepository(storage: storage);

  final ServerConfiguration? initialServerConfiguration =
      await serverConfigurationRepository.load();

  const String webServerUrl = String.fromEnvironment('SOFAWATCH_SERVER_URL');

  final Uri? configuredServerUrl = initialServerConfiguration?.serverUrl;

  final Uri? bootstrapServerUrl =
      configuredServerUrl ??
      (webServerUrl.isNotEmpty ? Uri.tryParse(webServerUrl) : null);

  final ApiClient apiClient = ApiClient(baseUrl: bootstrapServerUrl);

  final ServerConnectionTester serverConnectionTester =
      ApiServerConnectionTester();

  final AppBootstrapData data = AppBootstrapData(
    serverConfigurationRepository: serverConfigurationRepository,
    apiClient: apiClient,
    serverConnectionTester: serverConnectionTester,
    initialServerConfiguration: initialServerConfiguration,
    searchRepository: ApiSearchRepository(apiClient),
  );

  final Widget app = await builder(data);

  runApp(app);
}
