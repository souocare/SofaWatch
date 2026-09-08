import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_cubit.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_entry_cubit.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_entry_state.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_state.dart';
import 'package:sofawatch/features/auth/application/cubit/initial_setup_cubit.dart';
import 'package:sofawatch/features/auth/domain/models/auth_session.dart';
import 'package:sofawatch/features/auth/domain/models/setup_status.dart';
import 'package:sofawatch/features/auth/domain/repositories/auth_repository.dart';
import 'package:sofawatch/features/auth/domain/repositories/setup_status_repository.dart';
import 'package:sofawatch/features/auth/presentation/pages/initial_setup_page.dart';

void main() {
  group('InitialSetupPage', () {
    testWidgets('shows all initial account controls', (
      WidgetTester tester,
    ) async {
      final _FakeAuthRepository repository = _FakeAuthRepository();

      await tester.pumpWidget(_buildApp(repository: repository));

      expect(
        find.byKey(const ValueKey<String>('auth-initial-setup-page-title')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('auth-initial-setup-display-name-field'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('auth-initial-setup-username-field')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('auth-initial-setup-email-field')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('auth-initial-setup-password-field')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('auth-initial-setup-confirm-password-field'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('auth-initial-setup-submit-button')),
        findsOneWidget,
      );
    });

    testWidgets('shows inline validation for required fields', (
      WidgetTester tester,
    ) async {
      final _FakeAuthRepository repository = _FakeAuthRepository();

      await tester.pumpWidget(_buildApp(repository: repository));

      await _tapSubmit(tester);

      expect(find.text('Enter your display name.'), findsOneWidget);
      expect(find.text('Enter a username.'), findsOneWidget);
      expect(find.text('Enter a password.'), findsOneWidget);
      expect(find.text('Confirm your password.'), findsOneWidget);

      expect(repository.initialSetupCalls, 0);
    });

    testWidgets('submits the initial administrator account', (
      WidgetTester tester,
    ) async {
      final _FakeAuthRepository repository = _FakeAuthRepository();

      await tester.pumpWidget(_buildApp(repository: repository));

      await _fillValidForm(tester);

      await _tapSubmit(tester);
      await tester.pump();

      expect(repository.initialSetupCalls, 1);
      expect(repository.lastDisplayName, 'Gonçalo');
      expect(repository.lastUsername, 'souocare');
      expect(repository.lastEmail, 'goncalo@example.com');
      expect(repository.lastPassword, 'correct-password');
    });

    testWidgets('shows loading and disables submit while creating account', (
      WidgetTester tester,
    ) async {
      final _FakeAuthRepository repository = _FakeAuthRepository(
        waitForCompletion: true,
      );

      await tester.pumpWidget(_buildApp(repository: repository));

      await _fillValidForm(tester);

      await _tapSubmit(tester);
      await tester.pump();

      expect(find.text('Creating account…'), findsOneWidget);

      final FilledButton button = tester.widget<FilledButton>(
        find.byKey(const ValueKey<String>('auth-initial-setup-submit-button')),
      );

      expect(button.onPressed, isNull);
      expect(repository.initialSetupCalls, 1);

      repository.complete();

      await tester.pump();
      await tester.pump();
    });

    testWidgets('shows safe network failure', (WidgetTester tester) async {
      final _FakeAuthRepository repository = _FakeAuthRepository(
        error: const AppException.connection(),
      );

      await tester.pumpWidget(_buildApp(repository: repository));

      await _fillValidForm(tester);

      await _tapSubmit(tester);
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('auth-initial-setup-failure')),
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

    testWidgets(
      'successful setup promotes session and closes initial setup routing',
      (WidgetTester tester) async {
        final _FakeAuthRepository repository = _FakeAuthRepository();

        late AuthCubit authCubit;
        late AuthEntryCubit authEntryCubit;

        await tester.pumpWidget(
          _buildApp(
            repository: repository,
            onAuthCubitCreated: (AuthCubit cubit) {
              authCubit = cubit;
            },
            onAuthEntryCubitCreated: (AuthEntryCubit cubit) {
              authEntryCubit = cubit;
            },
          ),
        );

        await _fillValidForm(tester);

        await _tapSubmit(tester);
        await tester.pump();

        expect(authEntryCubit.state, const AuthEntryLoginRequired());

        expect(authCubit.state, const AuthAuthenticated(_session));
      },
    );

    testWidgets(
      'completed setup conflict transitions unauthenticated flow to login',
      (WidgetTester tester) async {
        final _FakeAuthRepository repository = _FakeAuthRepository(
          error: const AppException(
            type: AppExceptionType.conflict,
            code: 'initial_setup_completed',
            statusCode: 409,
            message: 'Initial SofaWatch setup has already been completed.',
          ),
        );

        late AuthCubit authCubit;
        late AuthEntryCubit authEntryCubit;

        await tester.pumpWidget(
          _buildApp(
            repository: repository,
            onAuthCubitCreated: (AuthCubit cubit) {
              authCubit = cubit;
            },
            onAuthEntryCubitCreated: (AuthEntryCubit cubit) {
              authEntryCubit = cubit;
            },
          ),
        );

        await _fillValidForm(tester);

        await _tapSubmit(tester);
        await tester.pump();

        expect(authEntryCubit.state, const AuthEntryLoginRequired());

        expect(authCubit.state, const AuthUnauthenticated());
      },
    );

    testWidgets('toggles both password visibility controls', (
      WidgetTester tester,
    ) async {
      final _FakeAuthRepository repository = _FakeAuthRepository();

      await tester.pumpWidget(_buildApp(repository: repository));

      TextField passwordField = tester.widget<TextField>(
        find.byKey(const ValueKey<String>('auth-initial-setup-password-field')),
      );

      TextField confirmPasswordField = tester.widget<TextField>(
        find.byKey(
          const ValueKey<String>('auth-initial-setup-confirm-password-field'),
        ),
      );

      expect(passwordField.obscureText, isTrue);
      expect(confirmPasswordField.obscureText, isTrue);

      await _tapControl(
        tester,
        find.byKey(
          const ValueKey<String>('auth-initial-setup-password-visibility'),
        ),
      );

      await _tapControl(
        tester,
        find.byKey(
          const ValueKey<String>(
            'auth-initial-setup-confirm-password-visibility',
          ),
        ),
      );

      passwordField = tester.widget<TextField>(
        find.byKey(const ValueKey<String>('auth-initial-setup-password-field')),
      );

      confirmPasswordField = tester.widget<TextField>(
        find.byKey(
          const ValueKey<String>('auth-initial-setup-confirm-password-field'),
        ),
      );

      expect(passwordField.obscureText, isFalse);
      expect(confirmPasswordField.obscureText, isFalse);
    });
  });
}

Future<void> _fillValidForm(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const ValueKey<String>('auth-initial-setup-display-name-field')),
    'Gonçalo',
  );

  await tester.enterText(
    find.byKey(const ValueKey<String>('auth-initial-setup-username-field')),
    'souocare',
  );

  await tester.enterText(
    find.byKey(const ValueKey<String>('auth-initial-setup-email-field')),
    'goncalo@example.com',
  );

  await tester.enterText(
    find.byKey(const ValueKey<String>('auth-initial-setup-password-field')),
    'correct-password',
  );

  await tester.enterText(
    find.byKey(
      const ValueKey<String>('auth-initial-setup-confirm-password-field'),
    ),
    'correct-password',
  );
}

Future<void> _tapSubmit(WidgetTester tester) async {
  final Finder submitButton = find.byKey(
    const ValueKey<String>('auth-initial-setup-submit-button'),
  );

  await tester.ensureVisible(submitButton);
  await tester.pumpAndSettle();

  await tester.tap(submitButton);
  await tester.pump();
}

Future<void> _tapControl(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();

  await tester.tap(finder);
  await tester.pump();
}

Widget _buildApp({
  required _FakeAuthRepository repository,
  void Function(AuthCubit cubit)? onAuthCubitCreated,
  void Function(AuthEntryCubit cubit)? onAuthEntryCubitCreated,
}) {
  final AuthCubit authCubit = AuthCubit(repository: repository);

  authCubit.authenticationLost();

  final AuthEntryCubit authEntryCubit = AuthEntryCubit(
    repository: _FakeSetupStatusRepository(),
  );

  onAuthCubitCreated?.call(authCubit);
  onAuthEntryCubitCreated?.call(authEntryCubit);

  return MultiBlocProvider(
    providers: <BlocProvider<dynamic>>[
      BlocProvider<AuthCubit>.value(value: authCubit),
      BlocProvider<AuthEntryCubit>.value(value: authEntryCubit),
      BlocProvider<InitialSetupCubit>(
        create: (BuildContext context) {
          return InitialSetupCubit(repository: repository);
        },
      ),
    ],
    child: const MaterialApp(home: InitialSetupPage()),
  );
}

const AuthSession _session = AuthSession(
  accessToken: 'setup-access-token',
  expiresIn: Duration(minutes: 15),
);

final class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.error, this.waitForCompletion = false});

  final AppException? error;
  final bool waitForCompletion;

  int initialSetupCalls = 0;

  String? lastUsername;
  String? lastDisplayName;
  String? lastPassword;
  String? lastEmail;

  Completer<void>? _completer;

  void complete() {
    final Completer<void>? completer = _completer;

    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  @override
  Future<AuthSession> initialSetup({
    required String username,
    required String displayName,
    required String password,
    String? email,
  }) async {
    initialSetupCalls += 1;

    lastUsername = username;
    lastDisplayName = displayName;
    lastPassword = password;
    lastEmail = email;

    if (waitForCompletion) {
      final Completer<void> completer = Completer<void>();
      _completer = completer;
      await completer.future;
    }

    final AppException? thrownError = error;

    if (thrownError != null) {
      throw thrownError;
    }

    return _session;
  }

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSession?> restore() async {
    return null;
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> logoutEverywhere() async {}

  @override
  Future<void> clearLocalAuthentication() async {}
}

final class _FakeSetupStatusRepository implements SetupStatusRepository {
  @override
  Future<SetupStatus> getStatus() async {
    return const SetupStatus(setupRequired: true);
  }
}
