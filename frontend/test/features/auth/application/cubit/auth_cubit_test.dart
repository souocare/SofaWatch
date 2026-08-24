import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_cubit.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_state.dart';
import 'package:sofawatch/features/auth/domain/models/auth_session.dart';
import 'package:sofawatch/features/auth/domain/repositories/auth_repository.dart';

void main() {
  group('AuthCubit', () {
    test('starts in initial state', () {
      final AuthCubit cubit = AuthCubit(repository: _FakeAuthRepository());

      expect(cubit.state, const AuthInitial());

      cubit.close();
    });

    test('emits checking and authenticated when session is restored', () async {
      const AuthSession session = AuthSession(
        accessToken: 'access-token',
        expiresIn: Duration(minutes: 15),
      );

      final AuthCubit cubit = AuthCubit(
        repository: _FakeAuthRepository(restoreResult: session),
      );

      final Future<void> expectation = expectLater(
        cubit.stream,
        emitsInOrder(<AuthState>[
          const AuthChecking(),
          const AuthAuthenticated(session),
        ]),
      );

      await cubit.restore();
      await expectation;

      expect(cubit.state, const AuthAuthenticated(session));

      await cubit.close();
    });

    test('emits unauthenticated when restore returns null', () async {
      final AuthCubit cubit = AuthCubit(repository: _FakeAuthRepository());

      final Future<void> expectation = expectLater(
        cubit.stream,
        emitsInOrder(<AuthState>[
          const AuthChecking(),
          const AuthUnauthenticated(),
        ]),
      );

      await cubit.restore();
      await expectation;

      expect(cubit.state, const AuthUnauthenticated());

      await cubit.close();
    });

    test('maps missing Web session to unauthenticated', () async {
      final AuthCubit cubit = AuthCubit(
        repository: _FakeAuthRepository(
          restoreError: const AppException(
            type: AppExceptionType.unauthorized,
            code: 'session_required',
            statusCode: 401,
            message: 'An authenticated session is required.',
          ),
        ),
      );

      final Future<void> expectation = expectLater(
        cubit.stream,
        emitsInOrder(<AuthState>[
          const AuthChecking(),
          const AuthUnauthenticated(),
        ]),
      );

      await cubit.restore();
      await expectation;

      expect(cubit.state, const AuthUnauthenticated());

      await cubit.close();
    });

    test('maps invalid persistent session to unauthenticated', () async {
      final AuthCubit cubit = AuthCubit(
        repository: _FakeAuthRepository(
          restoreError: const AppException(
            type: AppExceptionType.unauthorized,
            code: 'invalid_session',
            statusCode: 401,
            message: 'The authentication session is invalid or expired.',
          ),
        ),
      );

      final Future<void> expectation = expectLater(
        cubit.stream,
        emitsInOrder(<AuthState>[
          const AuthChecking(),
          const AuthUnauthenticated(),
        ]),
      );

      await cubit.restore();
      await expectation;

      expect(cubit.state, const AuthUnauthenticated());

      await cubit.close();
    });

    test('maps invalid Mobile refresh token to unauthenticated', () async {
      final AuthCubit cubit = AuthCubit(
        repository: _FakeAuthRepository(
          restoreError: const AppException(
            type: AppExceptionType.unauthorized,
            code: 'invalid_refresh_token',
            statusCode: 401,
            message: 'The refresh token is invalid or expired.',
          ),
        ),
      );

      final Future<void> expectation = expectLater(
        cubit.stream,
        emitsInOrder(<AuthState>[
          const AuthChecking(),
          const AuthUnauthenticated(),
        ]),
      );

      await cubit.restore();
      await expectation;

      expect(cubit.state, const AuthUnauthenticated());

      await cubit.close();
    });

    test(
      'emits failure when session restoration fails for another reason',
      () async {
        const AppException error = AppException.connection();

        final AuthCubit cubit = AuthCubit(
          repository: _FakeAuthRepository(restoreError: error),
        );

        final Future<void> expectation = expectLater(
          cubit.stream,
          emitsInOrder(<AuthState>[
            const AuthChecking(),
            const AuthFailure(error),
          ]),
        );

        await cubit.restore();
        await expectation;

        expect(cubit.state, const AuthFailure(error));

        await cubit.close();
      },
    );

    test('maps unexpected restore error to unknown failure', () async {
      final AuthCubit cubit = AuthCubit(
        repository: _FakeAuthRepository(
          restoreError: StateError('Unexpected failure.'),
        ),
      );

      await cubit.restore();

      expect(cubit.state, isA<AuthFailure>());

      final AuthFailure state = cubit.state as AuthFailure;

      expect(state.error.type, AppExceptionType.unknown);

      await cubit.close();
    });
    test('logs out current session and becomes unauthenticated', () async {
      const AuthSession session = AuthSession(
        accessToken: 'access-token',
        expiresIn: Duration(minutes: 15),
      );

      final _FakeAuthRepository repository = _FakeAuthRepository(
        restoreResult: session,
      );

      final AuthCubit cubit = AuthCubit(repository: repository);

      cubit.authenticated(session);

      final Future<void> expectation = expectLater(
        cubit.stream,
        emitsInOrder(<AuthState>[
          const AuthLoggingOut(),
          const AuthUnauthenticated(),
        ]),
      );

      await cubit.logout();
      await expectation;

      expect(repository.logoutCalls, 1);
      expect(cubit.state, const AuthUnauthenticated());

      await cubit.close();
    });

    test(
      'becomes unauthenticated even when current-session logout fails',
      () async {
        const AuthSession session = AuthSession(
          accessToken: 'access-token',
          expiresIn: Duration(minutes: 15),
        );

        final _FakeAuthRepository repository = _FakeAuthRepository(
          logoutError: const AppException.connection(),
        );

        final AuthCubit cubit = AuthCubit(repository: repository);

        cubit.authenticated(session);

        await cubit.logout();

        expect(repository.logoutCalls, 1);
        expect(cubit.state, const AuthUnauthenticated());

        await cubit.close();
      },
    );

    test('logs out everywhere and becomes unauthenticated', () async {
      const AuthSession session = AuthSession(
        accessToken: 'access-token',
        expiresIn: Duration(minutes: 15),
      );

      final _FakeAuthRepository repository = _FakeAuthRepository();

      final AuthCubit cubit = AuthCubit(repository: repository);

      cubit.authenticated(session);

      final Future<void> expectation = expectLater(
        cubit.stream,
        emitsInOrder(<AuthState>[
          const AuthLoggingOutEverywhere(),
          const AuthUnauthenticated(),
        ]),
      );

      await cubit.logoutEverywhere();
      await expectation;

      expect(repository.logoutEverywhereCalls, 1);
      expect(cubit.state, const AuthUnauthenticated());

      await cubit.close();
    });

    test(
      'becomes unauthenticated even when logout everywhere fails remotely',
      () async {
        const AuthSession session = AuthSession(
          accessToken: 'access-token',
          expiresIn: Duration(minutes: 15),
        );

        final _FakeAuthRepository repository = _FakeAuthRepository(
          logoutEverywhereError: const AppException.connection(),
        );

        final AuthCubit cubit = AuthCubit(repository: repository);

        cubit.authenticated(session);

        await cubit.logoutEverywhere();

        expect(repository.logoutEverywhereCalls, 1);
        expect(cubit.state, const AuthUnauthenticated());

        await cubit.close();
      },
    );
  });
}

final class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.restoreResult,
    this.restoreError,
    this.logoutError,
    this.logoutEverywhereError,
  });

  final AuthSession? restoreResult;
  final Object? restoreError;
  final Object? logoutError;
  final Object? logoutEverywhereError;

  int logoutCalls = 0;
  int logoutEverywhereCalls = 0;

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSession?> restore() async {
    final Object? error = restoreError;

    if (error != null) {
      throw error;
    }

    return restoreResult;
  }

  @override
  Future<void> logout() async {
    logoutCalls += 1;

    final Object? error = logoutError;

    if (error != null) {
      throw error;
    }
  }

  @override
  Future<void> logoutEverywhere() async {
    logoutEverywhereCalls += 1;

    final Object? error = logoutEverywhereError;

    if (error != null) {
      throw error;
    }
  }
}
