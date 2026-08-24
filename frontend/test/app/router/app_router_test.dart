import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/app_dependencies.dart';
import 'package:sofawatch/app/router/app_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/app/router/auth_router_refresh_notifier.dart';
import 'package:sofawatch/app/router/route_paths.dart';
import 'package:sofawatch/app/theme/app_theme.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_cubit.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_entry_cubit.dart';
import 'package:sofawatch/features/auth/data/repositories/api_auth_repository.dart';
import 'package:sofawatch/features/auth/data/repositories/api_setup_status_repository.dart';
import 'package:sofawatch/features/auth/data/storage/in_memory_access_token_store.dart';
import 'package:sofawatch/features/auth/domain/models/auth_session.dart';
import 'package:sofawatch/features/auth/domain/models/setup_status.dart';
import 'package:sofawatch/features/auth/domain/repositories/access_token_store.dart';
import 'package:sofawatch/features/auth/domain/repositories/auth_repository.dart';
import 'package:sofawatch/features/auth/domain/repositories/setup_status_repository.dart';
import 'package:sofawatch/features/search/application/bloc/search_bloc.dart';

import '../../fakes/fake_search_repository.dart';
import '../../fakes/fake_server_configuration_repository.dart';
import '../../fakes/fake_server_connection_tester.dart';

void main() {
  late GoRouter router;
  late ApiClient apiClient;

  setUp(() {
    final Dio dio = Dio();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 500,
              data: const <String, dynamic>{
                'error': <String, dynamic>{
                  'code': 'test_error',
                  'message': 'Test failure.',
                },
              },
            ),
          );
        },
      ),
    );

    apiClient = ApiClient(
      baseUrl: Uri.parse('https://server.example.com'),
      dio: dio,
    );

    router = createAppRouter(apiClient: apiClient);
  });

  tearDown(() {
    router.dispose();
  });

  Widget buildTestApp() {
    final AccessTokenStore accessTokenStore = InMemoryAccessTokenStore();

    final AuthRepository authRepository = ApiAuthRepository(
      apiClient: apiClient,
      accessTokenStore: accessTokenStore,
      isWeb: true,
    );

    final SetupStatusRepository setupStatusRepository =
        ApiSetupStatusRepository(apiClient);

    return AppDependencies(
      serverConfigurationRepository: FakeServerConfigurationRepository(),
      apiClient: apiClient,
      searchRepository: FakeSearchRepository(),
      serverConnectionTester: FakeServerConnectionTester(),
      accessTokenStore: accessTokenStore,
      authRepository: authRepository,
      setupStatusRepository: setupStatusRepository,
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
      ),
    );
  }

  testWidgets('redirects the root route to Home', (WidgetTester tester) async {
    router.go('/');

    await tester.pumpWidget(buildTestApp());

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('home-page')), findsOneWidget);
  });

  testWidgets('opens show details from a deep-link location', (
    WidgetTester tester,
  ) async {
    router.go('/shows/95396');

    await tester.pumpWidget(buildTestApp());

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('show-details-failure')),
      findsOneWidget,
    );
  });

  testWidgets('opens movie details from a deep-link location', (
    WidgetTester tester,
  ) async {
    router.goNamed(
      AppRoute.movieDetails.name,
      pathParameters: <String, String>{'movieId': '438631'},
    );

    await tester.pumpWidget(buildTestApp());

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('movie-details-failure')),
      findsOneWidget,
    );
  });

  testWidgets('opens episode details from a deep-link location', (
    WidgetTester tester,
  ) async {
    router.go('/episodes/episode-789');

    await tester.pumpWidget(buildTestApp());

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('episode-details-page')),
      findsOneWidget,
    );
  });

  testWidgets('shows a not-found page for an unknown route', (
    WidgetTester tester,
  ) async {
    router.go('/unknown-route');

    await tester.pumpWidget(buildTestApp());

    await tester.pumpAndSettle();

    expect(find.text('Page not found'), findsOneWidget);

    expect(
      find.byKey(const ValueKey<String>('not-found-location')),
      findsOneWidget,
    );

    expect(find.text('/unknown-route'), findsOneWidget);
  });

  testWidgets('returns Home from the not-found page', (
    WidgetTester tester,
  ) async {
    router.go('/unknown-route');

    await tester.pumpWidget(buildTestApp());

    await tester.pumpAndSettle();

    await tester.tap(find.text('Go to Home'));

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('home-page')), findsOneWidget);
  });

  testWidgets('opens the global Search route on mobile', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    router.goNamed(AppRoute.search.name);

    await tester.pumpWidget(buildTestApp());

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('search-mobile-view')),
      findsOneWidget,
    );

    expect(
      find.byKey(const ValueKey<String>('search-mobile-title')),
      findsOneWidget,
    );
  });

  testWidgets('opens the global Search route as a desktop modal', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 844));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    router.go('/home');

    await tester.pumpWidget(buildTestApp());

    await tester.pumpAndSettle();

    router.pushNamed(AppRoute.search.name);

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('search-desktop-modal')),
      findsOneWidget,
    );

    expect(
      find.byKey(const ValueKey<String>('search-text-field')),
      findsOneWidget,
    );
  });

  testWidgets('closes the desktop Search modal and returns to Home', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 844));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    router.go('/home');

    await tester.pumpWidget(buildTestApp());

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('home-page')), findsOneWidget);

    router.pushNamed(AppRoute.search.name);

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('search-desktop-modal')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('search-desktop-close-button')),
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('search-desktop-modal')),
      findsNothing,
    );

    expect(find.byKey(const ValueKey<String>('home-page')), findsOneWidget);
  });

  testWidgets('closes the SearchBloc when the Search route is popped', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    router.go('/home');

    await tester.pumpWidget(buildTestApp());

    await tester.pumpAndSettle();

    router.pushNamed(AppRoute.search.name);

    await tester.pumpAndSettle();

    final BuildContext searchContext = tester.element(
      find.byKey(const ValueKey<String>('search-mobile-view')),
    );

    final SearchBloc searchBloc = BlocProvider.of<SearchBloc>(searchContext);

    expect(searchBloc.isClosed, isFalse);

    router.pop();

    await tester.pumpAndSettle();

    expect(searchBloc.isClosed, isTrue);

    expect(find.byKey(const ValueKey<String>('home-page')), findsOneWidget);
  });

  group('authentication redirects', () {
    testWidgets(
      'redirects to authentication checking while auth state is initial',
      (WidgetTester tester) async {
        final _AuthRoutingHarness harness = _AuthRoutingHarness(
          apiClient: apiClient,
        );

        addTearDown(harness.dispose);

        harness.router.go(RoutePaths.search);

        await tester.pumpWidget(harness.buildApp());

        await tester.pump();

        expect(harness.currentUri.path, RoutePaths.authChecking);

        expect(harness.currentUri.queryParameters['from'], RoutePaths.search);
      },
    );

    testWidgets(
      'redirects unauthenticated user to Login when setup is complete',
      (WidgetTester tester) async {
        final _AuthRoutingHarness harness = _AuthRoutingHarness(
          apiClient: apiClient,
          setupRequired: false,
        );

        addTearDown(harness.dispose);

        await harness.resolveUnauthenticatedEntry();

        harness.router.go(RoutePaths.search);

        await tester.pumpWidget(harness.buildApp());

        await tester.pump();

        expect(harness.currentUri.path, RoutePaths.login);

        expect(harness.currentUri.queryParameters['from'], RoutePaths.search);
      },
    );

    testWidgets(
      'redirects unauthenticated user to Initial Setup when setup is required',
      (WidgetTester tester) async {
        final _AuthRoutingHarness harness = _AuthRoutingHarness(
          apiClient: apiClient,
          setupRequired: true,
        );

        addTearDown(harness.dispose);

        await harness.resolveUnauthenticatedEntry();

        harness.router.go(RoutePaths.search);

        await tester.pumpWidget(harness.buildApp());

        await tester.pump();

        expect(harness.currentUri.path, RoutePaths.initialSetup);

        expect(harness.currentUri.queryParameters['from'], RoutePaths.search);
      },
    );

    testWidgets('redirects authenticated user away from Login', (
      WidgetTester tester,
    ) async {
      final _AuthRoutingHarness harness = _AuthRoutingHarness(
        apiClient: apiClient,
        restoreSession: _authenticatedSession,
      );

      addTearDown(harness.dispose);

      await harness.authCubit.restore();

      final String destination = Uri(
        path: RoutePaths.login,
        queryParameters: <String, String>{'from': RoutePaths.search},
      ).toString();

      harness.router.go(destination);

      await tester.pumpWidget(harness.buildApp());

      await tester.pump();
      await tester.pump();

      expect(harness.currentUri.path, RoutePaths.search);
    });

    testWidgets('redirects authenticated user away from Initial Setup', (
      WidgetTester tester,
    ) async {
      final _AuthRoutingHarness harness = _AuthRoutingHarness(
        apiClient: apiClient,
        restoreSession: _authenticatedSession,
      );

      addTearDown(harness.dispose);

      await harness.authCubit.restore();

      final String destination = Uri(
        path: RoutePaths.initialSetup,
        queryParameters: <String, String>{'from': RoutePaths.search},
      ).toString();

      harness.router.go(destination);

      await tester.pumpWidget(harness.buildApp());

      await tester.pump();
      await tester.pump();

      expect(harness.currentUri.path, RoutePaths.search);
    });

    testWidgets('preserves show deep link when redirecting to Login', (
      WidgetTester tester,
    ) async {
      final _AuthRoutingHarness harness = _AuthRoutingHarness(
        apiClient: apiClient,
        setupRequired: false,
      );

      addTearDown(harness.dispose);

      await harness.resolveUnauthenticatedEntry();

      const String deepLink = '/shows/95396';

      harness.router.go(deepLink);

      await tester.pumpWidget(harness.buildApp());

      await tester.pump();

      expect(harness.currentUri.path, RoutePaths.login);

      expect(harness.currentUri.queryParameters['from'], deepLink);
    });

    testWidgets('preserves movie deep link when redirecting to Initial Setup', (
      WidgetTester tester,
    ) async {
      final _AuthRoutingHarness harness = _AuthRoutingHarness(
        apiClient: apiClient,
        setupRequired: true,
      );

      addTearDown(harness.dispose);

      await harness.resolveUnauthenticatedEntry();

      const String deepLink = '/movies/438631';

      harness.router.go(deepLink);

      await tester.pumpWidget(harness.buildApp());

      await tester.pump();

      expect(harness.currentUri.path, RoutePaths.initialSetup);

      expect(harness.currentUri.queryParameters['from'], deepLink);
    });

    testWidgets(
      'returns to original destination after authentication succeeds',
      (WidgetTester tester) async {
        final _AuthRoutingHarness harness = _AuthRoutingHarness(
          apiClient: apiClient,
          setupRequired: false,
        );

        addTearDown(harness.dispose);

        await harness.resolveUnauthenticatedEntry();

        final String deepLink = Uri(
          path: RoutePaths.search,
          queryParameters: const <String, String>{'source': 'deep-link'},
        ).toString();

        harness.router.go(deepLink);

        await tester.pumpWidget(harness.buildApp());

        await tester.pump();

        expect(harness.currentUri.path, RoutePaths.login);

        expect(harness.currentUri.queryParameters['from'], deepLink);

        harness.authRepository.restoreSession = _authenticatedSession;

        await harness.authCubit.restore();

        await tester.pump();
        await tester.pump();

        expect(harness.currentUri.path, RoutePaths.search);

        expect(harness.currentUri.queryParameters['source'], 'deep-link');
      },
    );
  });
}

const AuthSession _authenticatedSession = AuthSession(
  accessToken: 'authenticated-access-token',
  expiresIn: Duration(minutes: 15),
);

final class _AuthRoutingHarness {
  _AuthRoutingHarness({
    required this.apiClient,
    bool setupRequired = false,
    AuthSession? restoreSession,
  }) : authRepository = _FakeAuthRepository(restoreSession: restoreSession),
       setupStatusRepository = _FakeSetupStatusRepository(
         setupRequired: setupRequired,
       ),
       accessTokenStore = InMemoryAccessTokenStore() {
    authCubit = AuthCubit(repository: authRepository);

    authEntryCubit = AuthEntryCubit(repository: setupStatusRepository);

    refreshNotifier = AuthRouterRefreshNotifier(
      authStates: authCubit.stream,
      authEntryStates: authEntryCubit.stream,
    );

    router = createAppRouter(
      apiClient: apiClient,
      authCubit: authCubit,
      authEntryCubit: authEntryCubit,
      refreshListenable: refreshNotifier,
    );
  }

  final ApiClient apiClient;

  final InMemoryAccessTokenStore accessTokenStore;

  final _FakeAuthRepository authRepository;

  final _FakeSetupStatusRepository setupStatusRepository;

  late final AuthCubit authCubit;
  late final AuthEntryCubit authEntryCubit;

  late final AuthRouterRefreshNotifier refreshNotifier;

  late final GoRouter router;

  Uri get currentUri {
    return router.routeInformationProvider.value.uri;
  }

  Future<void> resolveUnauthenticatedEntry() async {
    await authCubit.restore();

    await authEntryCubit.load();
  }

  Widget buildApp() {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<AuthEntryCubit>.value(value: authEntryCubit),
      ],
      child: AppDependencies(
        serverConfigurationRepository: FakeServerConfigurationRepository(),
        apiClient: apiClient,
        searchRepository: FakeSearchRepository(),
        serverConnectionTester: FakeServerConnectionTester(),
        accessTokenStore: accessTokenStore,
        authRepository: authRepository,
        setupStatusRepository: setupStatusRepository,
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.dark,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
        ),
      ),
    );
  }

  Future<void> dispose() async {
    router.dispose();

    refreshNotifier.dispose();

    await authEntryCubit.close();

    await authCubit.close();
  }
}

final class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.restoreSession});

  AuthSession? restoreSession;

  @override
  Future<AuthSession?> restore() async {
    return restoreSession;
  }

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    return restoreSession ?? _authenticatedSession;
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> logoutEverywhere() async {}
}

final class _FakeSetupStatusRepository implements SetupStatusRepository {
  _FakeSetupStatusRepository({required this.setupRequired});

  final bool setupRequired;

  @override
  Future<SetupStatus> getStatus() async {
    return SetupStatus(setupRequired: setupRequired);
  }
}
