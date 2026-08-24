import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_cubit.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_handoff_exchange_cubit.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_state.dart';
import 'package:sofawatch/features/auth/domain/models/auth_handoff.dart';
import 'package:sofawatch/features/auth/domain/models/auth_session.dart';
import 'package:sofawatch/features/auth/domain/repositories/auth_handoff_repository.dart';
import 'package:sofawatch/features/auth/domain/repositories/auth_repository.dart';
import 'package:sofawatch/features/auth/presentation/pages/auth_handoff_exchange_page.dart';

void main() {
  group('AuthHandoffExchangePage', () {
    testWidgets(
      'waits for initial authentication restoration before exchanging handoff',
      (WidgetTester tester) async {
        final _ControlledAuthRepository authRepository =
            _ControlledAuthRepository();

        final AuthCubit authCubit = AuthCubit(repository: authRepository);

        final _FakeAuthHandoffRepository handoffRepository =
            _FakeAuthHandoffRepository(session: _session);

        final AuthHandoffExchangeCubit handoffCubit = AuthHandoffExchangeCubit(
          repository: handoffRepository,
        );

        addTearDown(authCubit.close);
        addTearDown(handoffCubit.close);

        final Future<void> restoreFuture = authCubit.restore();

        expect(authCubit.state, const AuthChecking());

        await tester.pumpWidget(
          _buildTestApp(
            authCubit: authCubit,
            handoffCubit: handoffCubit,
            token: 'handoff-token',
          ),
        );

        await tester.pump();

        expect(handoffRepository.exchangeCalls, 0);

        expect(
          find.byKey(const ValueKey<String>('auth-handoff-loading')),
          findsOneWidget,
        );

        authRepository.completeRestore(null);

        await restoreFuture;

        await tester.pump();
        await tester.pump();

        expect(handoffRepository.exchangeCalls, 1);
        expect(handoffRepository.lastToken, 'handoff-token');

        expect(authCubit.state, const AuthAuthenticated(_session));
      },
    );

    testWidgets('exchanges handoff and authenticates the application', (
      WidgetTester tester,
    ) async {
      final AuthCubit authCubit = AuthCubit(repository: _FakeAuthRepository());

      await authCubit.restore();

      expect(authCubit.state, const AuthUnauthenticated());

      final _FakeAuthHandoffRepository handoffRepository =
          _FakeAuthHandoffRepository(session: _session);

      final AuthHandoffExchangeCubit handoffCubit = AuthHandoffExchangeCubit(
        repository: handoffRepository,
      );

      addTearDown(authCubit.close);
      addTearDown(handoffCubit.close);

      await tester.pumpWidget(
        _buildTestApp(
          authCubit: authCubit,
          handoffCubit: handoffCubit,
          token: 'handoff-token',
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(handoffRepository.exchangeCalls, 1);
      expect(handoffRepository.lastToken, 'handoff-token');

      expect(authCubit.state, const AuthAuthenticated(_session));
    });

    testWidgets('shows invalid state when handoff token is missing', (
      WidgetTester tester,
    ) async {
      final AuthCubit authCubit = AuthCubit(repository: _FakeAuthRepository());

      await authCubit.restore();

      final _FakeAuthHandoffRepository handoffRepository =
          _FakeAuthHandoffRepository();

      final AuthHandoffExchangeCubit handoffCubit = AuthHandoffExchangeCubit(
        repository: handoffRepository,
      );

      addTearDown(authCubit.close);
      addTearDown(handoffCubit.close);

      await tester.pumpWidget(
        _buildTestApp(
          authCubit: authCubit,
          handoffCubit: handoffCubit,
          token: null,
        ),
      );

      await tester.pumpAndSettle();

      expect(handoffRepository.exchangeCalls, 0);

      expect(
        find.byKey(const ValueKey<String>('auth-handoff-invalid')),
        findsOneWidget,
      );

      expect(find.text('This link is no longer valid'), findsOneWidget);
    });

    testWidgets('shows invalid state when backend rejects handoff', (
      WidgetTester tester,
    ) async {
      final AuthCubit authCubit = AuthCubit(repository: _FakeAuthRepository());

      await authCubit.restore();

      final _FakeAuthHandoffRepository handoffRepository =
          _FakeAuthHandoffRepository(
            error: const AppException(
              type: AppExceptionType.unauthorized,
              code: 'invalid_auth_handoff',
              statusCode: 401,
              message: 'The authentication handoff is invalid or expired.',
            ),
          );

      final AuthHandoffExchangeCubit handoffCubit = AuthHandoffExchangeCubit(
        repository: handoffRepository,
      );

      addTearDown(authCubit.close);
      addTearDown(handoffCubit.close);

      await tester.pumpWidget(
        _buildTestApp(
          authCubit: authCubit,
          handoffCubit: handoffCubit,
          token: 'invalid-handoff-token',
        ),
      );

      await tester.pumpAndSettle();

      expect(handoffRepository.exchangeCalls, 1);

      expect(
        find.byKey(const ValueKey<String>('auth-handoff-invalid')),
        findsOneWidget,
      );

      expect(find.text('This link is no longer valid'), findsOneWidget);
    });

    testWidgets('shows safe failure and retries handoff exchange', (
      WidgetTester tester,
    ) async {
      final AuthCubit authCubit = AuthCubit(repository: _FakeAuthRepository());

      await authCubit.restore();

      final _FakeAuthHandoffRepository handoffRepository =
          _FakeAuthHandoffRepository(
            errors: <Object>[const AppException.connection()],
            session: _session,
          );

      final AuthHandoffExchangeCubit handoffCubit = AuthHandoffExchangeCubit(
        repository: handoffRepository,
      );

      addTearDown(authCubit.close);
      addTearDown(handoffCubit.close);

      await tester.pumpWidget(
        _buildTestApp(
          authCubit: authCubit,
          handoffCubit: handoffCubit,
          token: 'handoff-token',
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(handoffRepository.exchangeCalls, 1);

      expect(
        find.byKey(const ValueKey<String>('auth-handoff-failure')),
        findsOneWidget,
      );

      expect(find.text('Could not open SofaWatch'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('auth-handoff-retry')),
      );

      await tester.pump();
      await tester.pump();

      expect(handoffRepository.exchangeCalls, 2);
      expect(handoffRepository.lastToken, 'handoff-token');

      expect(authCubit.state, const AuthAuthenticated(_session));

      expect(
        find.byKey(const ValueKey<String>('auth-handoff-failure')),
        findsNothing,
      );
    });
  });
}

Widget _buildTestApp({
  required AuthCubit authCubit,
  required AuthHandoffExchangeCubit handoffCubit,
  required String? token,
}) {
  return MultiBlocProvider(
    providers: <BlocProvider<dynamic>>[
      BlocProvider<AuthCubit>.value(value: authCubit),
      BlocProvider<AuthHandoffExchangeCubit>.value(value: handoffCubit),
    ],
    child: MaterialApp(home: AuthHandoffExchangePage(token: token)),
  );
}

const AuthSession _session = AuthSession(
  accessToken: 'web-access-token',
  expiresIn: Duration(minutes: 15),
);

final class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.restoreSession});

  final AuthSession? restoreSession;

  @override
  Future<AuthSession?> restore() async {
    return restoreSession;
  }

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> logoutEverywhere() async {}
}

final class _ControlledAuthRepository implements AuthRepository {
  final Completer<AuthSession?> _restoreCompleter = Completer<AuthSession?>();

  void completeRestore(AuthSession? session) {
    _restoreCompleter.complete(session);
  }

  @override
  Future<AuthSession?> restore() {
    return _restoreCompleter.future;
  }

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> logoutEverywhere() async {}
}

final class _FakeAuthHandoffRepository implements AuthHandoffRepository {
  _FakeAuthHandoffRepository({this.session, this.error, List<Object>? errors})
    : _errors = errors ?? <Object>[];

  final AuthSession? session;
  final Object? error;

  final List<Object> _errors;

  int exchangeCalls = 0;
  String? lastToken;

  @override
  Future<AuthHandoff> create() {
    throw UnimplementedError();
  }

  @override
  Future<AuthSession> exchange(String token) async {
    exchangeCalls += 1;
    lastToken = token;

    if (_errors.isNotEmpty) {
      throw _errors.removeAt(0);
    }

    final Object? exchangeError = error;

    if (exchangeError != null) {
      throw exchangeError;
    }

    return session ?? _session;
  }
}
