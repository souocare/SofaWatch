import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:sofawatch/app/router/route_paths.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_cubit.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_state.dart';
import 'package:sofawatch/features/auth/application/cubit/registration_cubit.dart';
import 'package:sofawatch/features/auth/data/repositories/api_auth_repository.dart';
import 'package:sofawatch/features/auth/data/storage/in_memory_access_token_store.dart';
import 'package:sofawatch/features/auth/domain/models/auth_session.dart';
import 'package:sofawatch/features/auth/domain/repositories/registration_repository.dart';
import 'package:sofawatch/features/auth/presentation/pages/registration_page.dart';
import 'package:sofawatch/core/api/api_client.dart';

void main() {
  group('RegistrationPage', () {
    testWidgets('shows registration form when registration is open', (
      WidgetTester tester,
    ) async {
      final _RegistrationHarness harness = _RegistrationHarness(
        repository: _FakeRegistrationRepository(),
      );

      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.buildApp());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('auth-registration-title')),
        findsOneWidget,
      );

      for (final String key in <String>[
        'auth-registration-username',
        'auth-registration-display-name',
        'auth-registration-email',
        'auth-registration-password',
        'auth-registration-confirm-password',
        'auth-registration-submit',
      ]) {
        expect(find.byKey(ValueKey<String>(key)), findsOneWidget);
      }
    });

    testWidgets('hides form when registration is closed', (
      WidgetTester tester,
    ) async {
      final _RegistrationHarness harness = _RegistrationHarness(
        repository: _FakeRegistrationRepository(isOpen: false),
      );

      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.buildApp());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('auth-registration-closed')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('auth-registration-submit')),
        findsNothing,
      );

      expect(harness.repository.registerCalls, 0);
    });

    testWidgets('shows retry when availability request fails', (
      WidgetTester tester,
    ) async {
      final _RegistrationHarness harness = _RegistrationHarness(
        repository: _FakeRegistrationRepository(
          availabilityError: const AppException(
            type: AppExceptionType.connection,
            message: 'Connection failed.',
          ),
        ),
      );

      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.buildApp());
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('auth-registration-availability-error'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('auth-registration-retry')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('auth-registration-submit')),
        findsNothing,
      );
    });

    testWidgets('validates password confirmation', (WidgetTester tester) async {
      final _RegistrationHarness harness = _RegistrationHarness(
        repository: _FakeRegistrationRepository(),
      );

      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.buildApp());
      await tester.pumpAndSettle();

      await _fillRegistration(tester, confirmPassword: 'different-password');

      await _submit(tester);

      expect(find.text('Passwords do not match.'), findsOneWidget);
      expect(harness.repository.registerCalls, 0);
    });

    testWidgets('authenticates the user after successful registration', (
      WidgetTester tester,
    ) async {
      final _RegistrationHarness harness = _RegistrationHarness(
        repository: _FakeRegistrationRepository(),
      );

      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.buildApp());
      await tester.pumpAndSettle();

      await _fillRegistration(tester);
      await _submit(tester);

      expect(harness.repository.registerCalls, 1);
      expect(harness.authCubit.state, isA<AuthAuthenticated>());

      final AuthAuthenticated authenticated =
          harness.authCubit.state as AuthAuthenticated;

      expect(authenticated.session.accessToken, _session.accessToken);
    });

    testWidgets('shows a useful message for a duplicate username', (
      WidgetTester tester,
    ) async {
      final _RegistrationHarness harness = _RegistrationHarness(
        repository: _FakeRegistrationRepository(
          registrationError: const AppException(
            type: AppExceptionType.conflict,
            code: 'username_already_exists',
            statusCode: 409,
            message: 'That username is already in use.',
          ),
        ),
      );

      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.buildApp());
      await tester.pumpAndSettle();

      await _fillRegistration(tester);
      await _submit(tester);

      expect(
        find.text('That username is already in use. Please choose another.'),
        findsOneWidget,
      );

      expect(harness.authCubit.state, isNot(isA<AuthAuthenticated>()));
    });

    testWidgets('disables submission while creating an account', (
      WidgetTester tester,
    ) async {
      final _FakeRegistrationRepository repository =
          _FakeRegistrationRepository(waitForCompletion: true);

      final _RegistrationHarness harness = _RegistrationHarness(
        repository: repository,
      );

      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.buildApp());
      await tester.pumpAndSettle();

      await _fillRegistration(tester);
      await _submit(tester);

      expect(find.text('Creating account…'), findsOneWidget);

      final FilledButton button = tester.widget<FilledButton>(
        find.byKey(const ValueKey<String>('auth-registration-submit')),
      );

      expect(button.onPressed, isNull);

      repository.complete();

      await tester.pumpAndSettle();

      expect(harness.authCubit.state, isA<AuthAuthenticated>());
    });

    testWidgets('allows returning to the Login page', (
      WidgetTester tester,
    ) async {
      final _RegistrationHarness harness = _RegistrationHarness(
        repository: _FakeRegistrationRepository(),
      );

      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.buildApp());
      await tester.pumpAndSettle();

      final Finder loginLink = find.byKey(
        const ValueKey<String>('auth-registration-login-link'),
      );

      await tester.ensureVisible(loginLink);
      await tester.tap(loginLink);
      await tester.pumpAndSettle();

      expect(
        harness.router.routeInformationProvider.value.uri.path,
        RoutePaths.login,
      );
    });
  });
}

Future<void> _fillRegistration(
  WidgetTester tester, {
  String confirmPassword = 'secure-password',
}) async {
  await tester.enterText(
    find.byKey(const ValueKey<String>('auth-registration-username')),
    'newuser',
  );

  await tester.enterText(
    find.byKey(const ValueKey<String>('auth-registration-display-name')),
    'New User',
  );

  await tester.enterText(
    find.byKey(const ValueKey<String>('auth-registration-email')),
    'new@example.com',
  );

  await tester.enterText(
    find.byKey(const ValueKey<String>('auth-registration-password')),
    'secure-password',
  );

  await tester.enterText(
    find.byKey(const ValueKey<String>('auth-registration-confirm-password')),
    confirmPassword,
  );
}

Future<void> _submit(WidgetTester tester) async {
  final Finder submit = find.byKey(
    const ValueKey<String>('auth-registration-submit'),
  );

  await tester.ensureVisible(submit);
  await tester.tap(submit);
  await tester.pump();
  await tester.pump();
}

const AuthSession _session = AuthSession(
  accessToken: 'registered-access-token',
  expiresIn: Duration(minutes: 15),
);

class _RegistrationHarness {
  _RegistrationHarness({required this.repository}) {
    authCubit = AuthCubit(
      repository: ApiAuthRepository(
        apiClient: ApiClient(baseUrl: Uri.parse('https://sofawatch.test')),
        accessTokenStore: InMemoryAccessTokenStore(),
        isWeb: true,
      ),
    );

    router = GoRouter(
      initialLocation: RoutePaths.register,
      routes: <RouteBase>[
        GoRoute(
          path: RoutePaths.register,
          builder: (context, state) {
            return BlocProvider<RegistrationCubit>(
              create: (_) => RegistrationCubit(repository: repository),
              child: const RegistrationPage(),
            );
          },
        ),
        GoRoute(
          path: RoutePaths.login,
          builder: (context, state) {
            return const Scaffold(body: Center(child: Text('Login test page')));
          },
        ),
      ],
    );
  }

  final _FakeRegistrationRepository repository;

  late final AuthCubit authCubit;
  late final GoRouter router;

  Widget buildApp() {
    return BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: MaterialApp.router(routerConfig: router),
    );
  }

  Future<void> dispose() async {
    router.dispose();
    await authCubit.close();
  }
}

class _FakeRegistrationRepository implements RegistrationRepository {
  _FakeRegistrationRepository({
    this.isOpen = true,
    this.availabilityError,
    this.registrationError,
    this.waitForCompletion = false,
  });

  final bool isOpen;
  final AppException? availabilityError;
  final AppException? registrationError;
  final bool waitForCompletion;

  int registerCalls = 0;

  Completer<void>? _completer;

  @override
  Future<bool> isRegistrationOpen() async {
    if (availabilityError != null) {
      throw availabilityError!;
    }

    return isOpen;
  }

  @override
  Future<AuthSession> register({
    required String username,
    required String displayName,
    required String password,
    String? email,
  }) async {
    registerCalls++;

    if (waitForCompletion) {
      _completer = Completer<void>();
      await _completer!.future;
    }

    if (registrationError != null) {
      throw registrationError!;
    }

    return _session;
  }

  void complete() {
    final Completer<void>? completer = _completer;

    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }
}
