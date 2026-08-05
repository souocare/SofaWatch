import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/app_bootstrap_data.dart';
import 'package:sofawatch/app/app_dependencies.dart';
import 'package:sofawatch/app/router/app_router.dart';
import 'package:sofawatch/app/theme/app_theme.dart';
import 'package:sofawatch/core/api/api_client.dart';

class SofaWatchApp extends StatefulWidget {
  const SofaWatchApp({this.bootstrapData, super.key});

  final AppBootstrapData? bootstrapData;

  @override
  State<SofaWatchApp> createState() {
    return _SofaWatchAppState();
  }
}

class _SofaWatchAppState extends State<SofaWatchApp> {
  late final ApiClient _apiClient;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    _apiClient = widget.bootstrapData?.apiClient ?? ApiClient();

    _router = createAppRouter(apiClient: _apiClient);
  }

  @override
  void dispose() {
    _router.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget app = MaterialApp.router(
      title: 'SofaWatch',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
    );

    final AppBootstrapData? bootstrapData = widget.bootstrapData;

    if (bootstrapData == null) {
      return app;
    }

    return AppDependencies(
      serverConfigurationRepository:
          bootstrapData.serverConfigurationRepository,
      apiClient: _apiClient,
      searchRepository: bootstrapData.searchRepository,
      serverConnectionTester: bootstrapData.serverConnectionTester,
      child: MaterialApp.router(
        routerConfig: _router,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
      ),
    );
  }
}
