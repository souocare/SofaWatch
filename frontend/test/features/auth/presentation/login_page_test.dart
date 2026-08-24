import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_cubit.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_state.dart';
import 'package:sofawatch/features/auth/application/cubit/login_cubit.dart';
import 'package:sofawatch/features/auth/domain/models/auth_session.dart';
import 'package:sofawatch/features/auth/domain/repositories/auth_repository.dart';
import 'package:sofawatch/features/auth/presentation/pages/login_page.dart';

void main() {
  group('LoginPage', () {
    testWidgets('shows username, password and submit controls', (
      WidgetTester tester,
    ) async {
      final _FakeAuthRepository repository = _FakeAuthRepository();

      await tester.pumpWidget(_buildApp(repository: repository));

      expect(
        find.byKey(const ValueKey<String>('auth-login-page-title')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('auth-login-username-field')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('auth-login-password-field')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('auth-login-submit-button')),
        findsOneWidget,
      );
    });

    testWidgets('shows inline validation for empty fields', (
      WidgetTester tester,
    ) async {
      final _FakeAuthRepository repository = _FakeAuthRepository();

      await tester.pumpWidget(_buildApp(repository: repository));

      await tester.tap(
        find.byKey(const ValueKey<String>('auth-login-submit-button')),
      );

      await tester.pump();

      expect(find.text('Enter your username or email.'), findsOneWidget);

      expect(find.text('Enter your password.'), findsOneWidget);

      expect(repository.loginCallCount, 0);
    });

    testWidgets('submits username and password', (WidgetTester tester) async {
      final _FakeAuthRepository repository = _FakeAuthRepository(
        session: _session,
      );

      await tester.pumpWidget(_buildApp(repository: repository));

      await tester.enterText(
        find.byKey(const ValueKey<String>('auth-login-username-field')),
        'souocare',
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('auth-login-password-field')),
        'correct-password',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('auth-login-submit-button')),
      );

      await tester.pump();
      await tester.pump();

      expect(repository.loginCallCount, 1);

      expect(repository.lastUsername, 'souocare');

      expect(repository.lastPassword, 'correct-password');
    });

    testWidgets('shows loading while login is in progress', (
      WidgetTester tester,
    ) async {
      final _FakeAuthRepository repository = _FakeAuthRepository(
        waitForCompletion: true,
      );

      await tester.pumpWidget(_buildApp(repository: repository));

      await tester.enterText(
        find.byKey(const ValueKey<String>('auth-login-username-field')),
        'souocare',
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('auth-login-password-field')),
        'password',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('auth-login-submit-button')),
      );

      await tester.pump();

      expect(find.text('Signing in…'), findsOneWidget);

      final FilledButton button = tester.widget<FilledButton>(
        find.byKey(const ValueKey<String>('auth-login-submit-button')),
      );

      expect(button.onPressed, isNull);

      repository.complete();

      await tester.pump();
      await tester.pump();
    });

    testWidgets('shows safe message for invalid credentials', (
      WidgetTester tester,
    ) async {
      final _FakeAuthRepository repository = _FakeAuthRepository(
        error: const AppException(
          type: AppExceptionType.unauthorized,
          code: 'invalid_credentials',
          statusCode: 401,
          message: 'The username or password is incorrect.',
        ),
      );

      await tester.pumpWidget(_buildApp(repository: repository));

      await tester.enterText(
        find.byKey(const ValueKey<String>('auth-login-username-field')),
        'inactive-or-invalid-user',
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('auth-login-password-field')),
        'wrong-password',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('auth-login-submit-button')),
      );

      await tester.pump();
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('auth-login-invalid-credentials')),
        findsOneWidget,
      );

      expect(
        find.text('The username or password is incorrect.'),
        findsOneWidget,
      );

      final Finder errorMessage = find.byKey(
        const ValueKey<String>('auth-login-invalid-credentials'),
      );

      expect(errorMessage, findsOneWidget);

      expect(
        find.descendant(
          of: errorMessage,
          matching: find.text('The username or password is incorrect.'),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: errorMessage,
          matching: find.textContaining('inactive'),
        ),
        findsNothing,
      );
    });

    testWidgets('shows safe network failure', (WidgetTester tester) async {
      final _FakeAuthRepository repository = _FakeAuthRepository(
        error: const AppException.connection(),
      );

      await tester.pumpWidget(_buildApp(repository: repository));

      await tester.enterText(
        find.byKey(const ValueKey<String>('auth-login-username-field')),
        'souocare',
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('auth-login-password-field')),
        'password',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('auth-login-submit-button')),
      );

      await tester.pump();
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('auth-login-failure')),
        findsOneWidget,
      );

      expect(
        find.text(
          'Could not connect to the server. '
          'Check the address and your network connection.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('promotes successful login to global authentication', (
      WidgetTester tester,
    ) async {
      final _FakeAuthRepository repository = _FakeAuthRepository(
        session: _session,
      );

      late AuthCubit authCubit;

      await tester.pumpWidget(
        _buildApp(
          repository: repository,
          onAuthCubitCreated: (AuthCubit cubit) {
            authCubit = cubit;
          },
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('auth-login-username-field')),
        'souocare',
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('auth-login-password-field')),
        'correct-password',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('auth-login-submit-button')),
      );

      await tester.pump();
      await tester.pump();

      expect(authCubit.state, const AuthAuthenticated(_session));
    });

    testWidgets('toggles password visibility', (WidgetTester tester) async {
      final _FakeAuthRepository repository = _FakeAuthRepository();

      await tester.pumpWidget(_buildApp(repository: repository));

      TextField passwordField = tester.widget<TextField>(
        find.byKey(const ValueKey<String>('auth-login-password-field')),
      );

      expect(passwordField.obscureText, isTrue);

      await tester.tap(
        find.byKey(const ValueKey<String>('auth-login-password-visibility')),
      );

      await tester.pump();

      passwordField = tester.widget<TextField>(
        find.byKey(const ValueKey<String>('auth-login-password-field')),
      );

      expect(passwordField.obscureText, isFalse);
    });
  });
}

Widget _buildApp({
  required _FakeAuthRepository repository,
  void Function(AuthCubit cubit)? onAuthCubitCreated,
}) {
  final AuthCubit authCubit = AuthCubit(repository: repository);

  onAuthCubitCreated?.call(authCubit);

  return MultiBlocProvider(
    providers: <BlocProvider<dynamic>>[
      BlocProvider<AuthCubit>.value(value: authCubit),
      BlocProvider<LoginCubit>(
        create: (BuildContext context) {
          return LoginCubit(repository: repository);
        },
      ),
    ],
    child: const MaterialApp(home: LoginPage()),
  );
}

const AuthSession _session = AuthSession(
  accessToken: 'access-token',
  expiresIn: Duration(minutes: 15),
);

final class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.session,
    this.error,
    this.waitForCompletion = false,
  });

  final AuthSession? session;
  final AppException? error;
  final bool waitForCompletion;

  int loginCallCount = 0;

  String? lastUsername;
  String? lastPassword;

  Completer<void>? _completer;

  void complete() {
    final Completer<void>? completer = _completer;

    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    loginCallCount += 1;

    lastUsername = username;
    lastPassword = password;

    if (waitForCompletion) {
      final Completer<void> completer = Completer<void>();

      _completer = completer;

      await completer.future;
    }

    final AppException? thrownError = error;

    if (thrownError != null) {
      throw thrownError;
    }

    return session ?? _session;
  }

  @override
  Future<AuthSession?> restore() async {
    return session;
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> logoutEverywhere() async {}
}
