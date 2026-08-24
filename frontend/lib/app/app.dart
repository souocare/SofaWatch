import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/app_bootstrap_data.dart';
import 'package:sofawatch/app/app_dependencies.dart';
import 'package:sofawatch/app/router/app_router.dart';
import 'package:sofawatch/app/router/auth_router_refresh_notifier.dart';
import 'package:sofawatch/app/theme/app_theme.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_cubit.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_entry_cubit.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_state.dart';

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

  StreamSubscription<AuthState>? _authStateSubscription;

  AuthCubit? _authCubit;
  AuthEntryCubit? _authEntryCubit;
  AuthRouterRefreshNotifier? _authRouterRefreshNotifier;

  @override
  void initState() {
    super.initState();

    final AppBootstrapData? bootstrapData = widget.bootstrapData;

    _apiClient = bootstrapData?.apiClient ?? ApiClient();

    if (bootstrapData == null) {
      _router = createAppRouter(apiClient: _apiClient);

      return;
    }

    final AuthCubit authCubit = AuthCubit(
      repository: bootstrapData.authRepository,
    );

    final AuthEntryCubit authEntryCubit = AuthEntryCubit(
      repository: bootstrapData.setupStatusRepository,
    );

    final AuthRouterRefreshNotifier authRouterRefreshNotifier =
        AuthRouterRefreshNotifier(
          authStates: authCubit.stream,
          authEntryStates: authEntryCubit.stream,
        );

    _authCubit = authCubit;
    _authEntryCubit = authEntryCubit;
    _authRouterRefreshNotifier = authRouterRefreshNotifier;

    _authStateSubscription = authCubit.stream.listen((AuthState state) {
      if (state is AuthUnauthenticated) {
        unawaited(authEntryCubit.load());
      }
    });

    _router = createAppRouter(
      apiClient: _apiClient,
      authCubit: authCubit,
      authEntryCubit: authEntryCubit,
      refreshListenable: authRouterRefreshNotifier,
    );

    unawaited(authCubit.restore());
  }

  @override
  void dispose() {
    _router.dispose();

    _authRouterRefreshNotifier?.dispose();

    final AuthCubit? authCubit = _authCubit;
    final StreamSubscription<AuthState>? authStateSubscription =
        _authStateSubscription;

    if (authStateSubscription != null) {
      unawaited(authStateSubscription.cancel());
    }

    final AuthEntryCubit? authEntryCubit = _authEntryCubit;

    if (authEntryCubit != null) {
      unawaited(authEntryCubit.close());
    }

    if (authCubit != null) {
      unawaited(authCubit.close());
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppBootstrapData? bootstrapData = widget.bootstrapData;

    if (bootstrapData == null) {
      return MaterialApp.router(
        title: 'SofaWatch',
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
      );
    }

    final AuthCubit authCubit = _authCubit!;
    final AuthEntryCubit authEntryCubit = _authEntryCubit!;

    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<AuthEntryCubit>.value(value: authEntryCubit),
      ],
      child: AppDependencies(
        serverConfigurationRepository:
            bootstrapData.serverConfigurationRepository,
        apiClient: _apiClient,
        searchRepository: bootstrapData.searchRepository,
        serverConnectionTester: bootstrapData.serverConnectionTester,
        accessTokenStore: bootstrapData.accessTokenStore,
        authRepository: bootstrapData.authRepository,
        authHandoffRepository: bootstrapData.authHandoffRepository,
        setupStatusRepository: bootstrapData.setupStatusRepository,
        child: MaterialApp.router(
          title: 'SofaWatch',
          debugShowCheckedModeBanner: false,
          routerConfig: _router,
          theme: AppTheme.dark,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
        ),
      ),
    );
  }
}
