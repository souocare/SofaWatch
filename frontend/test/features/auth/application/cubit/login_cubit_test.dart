import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/application/cubit/login_cubit.dart';
import 'package:sofawatch/features/auth/application/cubit/login_state.dart';
import 'package:sofawatch/features/auth/domain/models/auth_session.dart';
import 'package:sofawatch/features/auth/domain/repositories/auth_repository.dart';

void main() {
  group('LoginCubit', () {
    test('starts in LoginInitial', () {
      final _FakeAuthRepository repository = _FakeAuthRepository();

      final LoginCubit cubit = LoginCubit(repository: repository);

      expect(cubit.state, const LoginInitial());

      cubit.close();
    });

    test('validates empty username and password', () async {
      final _FakeAuthRepository repository = _FakeAuthRepository();

      final LoginCubit cubit = LoginCubit(repository: repository);

      final List<LoginState> states = <LoginState>[];

      final subscription = cubit.stream.listen(states.add);

      await cubit.submit(username: '   ', password: '');

      expect(states, <LoginState>[
        const LoginValidationFailure(
          usernameError: 'Enter your username or email.',
          passwordError: 'Enter your password.',
        ),
      ]);

      expect(repository.loginCallCount, 0);

      await subscription.cancel();
      await cubit.close();
    });

    test('validates empty username only', () async {
      final _FakeAuthRepository repository = _FakeAuthRepository();

      final LoginCubit cubit = LoginCubit(repository: repository);

      await cubit.submit(username: '', password: 'password');

      expect(
        cubit.state,
        const LoginValidationFailure(
          usernameError: 'Enter your username or email.',
        ),
      );

      expect(repository.loginCallCount, 0);

      await cubit.close();
    });

    test('validates empty password only', () async {
      final _FakeAuthRepository repository = _FakeAuthRepository();

      final LoginCubit cubit = LoginCubit(repository: repository);

      await cubit.submit(username: 'souocare', password: '');

      expect(
        cubit.state,
        const LoginValidationFailure(passwordError: 'Enter your password.'),
      );

      expect(repository.loginCallCount, 0);

      await cubit.close();
    });

    test('emits submitting and success for valid credentials', () async {
      final _FakeAuthRepository repository = _FakeAuthRepository(
        session: _session,
      );

      final LoginCubit cubit = LoginCubit(repository: repository);

      final Future<void> expectation = expectLater(
        cubit.stream,
        emitsInOrder(<LoginState>[
          const LoginSubmitting(),
          const LoginSuccess(_session),
        ]),
      );

      await cubit.submit(
        username: '  souocare  ',
        password: 'correct-password',
      );

      await expectation;

      expect(repository.loginCallCount, 1);

      expect(repository.lastUsername, 'souocare');

      expect(repository.lastPassword, 'correct-password');

      await cubit.close();
    });

    test('maps invalid credentials to LoginInvalidCredentials', () async {
      final _FakeAuthRepository repository = _FakeAuthRepository(
        error: const AppException(
          type: AppExceptionType.unauthorized,
          code: 'invalid_credentials',
          statusCode: 401,
          message: 'The username or password is incorrect.',
        ),
      );

      final LoginCubit cubit = LoginCubit(repository: repository);

      final Future<void> expectation = expectLater(
        cubit.stream,
        emitsInOrder(<LoginState>[
          const LoginSubmitting(),
          const LoginInvalidCredentials(),
        ]),
      );

      await cubit.submit(username: 'souocare', password: 'wrong-password');

      await expectation;

      expect(repository.loginCallCount, 1);

      await cubit.close();
    });

    test('does not expose inactive user through a distinct state', () async {
      final _FakeAuthRepository repository = _FakeAuthRepository(
        error: const AppException(
          type: AppExceptionType.unauthorized,
          code: 'invalid_credentials',
          statusCode: 401,
          message: 'The username or password is incorrect.',
        ),
      );

      final LoginCubit cubit = LoginCubit(repository: repository);

      await cubit.submit(username: 'inactive-user', password: 'password');

      expect(cubit.state, const LoginInvalidCredentials());

      await cubit.close();
    });

    test('preserves network failure', () async {
      final AppException error = const AppException.connection();

      final _FakeAuthRepository repository = _FakeAuthRepository(error: error);

      final LoginCubit cubit = LoginCubit(repository: repository);

      await cubit.submit(username: 'souocare', password: 'password');

      expect(cubit.state, LoginFailure(error));

      await cubit.close();
    });

    test('maps unexpected failure to unknown', () async {
      final _FakeAuthRepository repository = _FakeAuthRepository(
        unexpectedError: StateError('Unexpected authentication failure.'),
      );

      final LoginCubit cubit = LoginCubit(repository: repository);

      await cubit.submit(username: 'souocare', password: 'password');

      final LoginState state = cubit.state;

      expect(state, isA<LoginFailure>());

      final LoginFailure failure = state as LoginFailure;

      expect(failure.error.type, AppExceptionType.unknown);

      await cubit.close();
    });

    test(
      'ignores another submit while authentication is in progress',
      () async {
        final _FakeAuthRepository repository = _FakeAuthRepository(
          session: _session,
          waitForCompletion: true,
        );

        final LoginCubit cubit = LoginCubit(repository: repository);

        final Future<void> firstSubmit = cubit.submit(
          username: 'souocare',
          password: 'password',
        );

        await Future<void>.delayed(Duration.zero);

        expect(cubit.state, const LoginSubmitting());

        await cubit.submit(
          username: 'another-user',
          password: 'another-password',
        );

        expect(repository.loginCallCount, 1);

        repository.complete();

        await firstSubmit;

        expect(cubit.state, const LoginSuccess(_session));

        await cubit.close();
      },
    );

    test('clearFeedback returns to initial state', () async {
      final _FakeAuthRepository repository = _FakeAuthRepository(
        error: const AppException(
          type: AppExceptionType.unauthorized,
          code: 'invalid_credentials',
          statusCode: 401,
          message: 'The username or password is incorrect.',
        ),
      );

      final LoginCubit cubit = LoginCubit(repository: repository);

      await cubit.submit(username: 'souocare', password: 'wrong');

      expect(cubit.state, const LoginInvalidCredentials());

      cubit.clearFeedback();

      expect(cubit.state, const LoginInitial());

      await cubit.close();
    });
  });
}

const AuthSession _session = AuthSession(
  accessToken: 'access-token',
  expiresIn: Duration(minutes: 15),
);

final class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.session,
    this.error,
    this.unexpectedError,
    this.waitForCompletion = false,
  });

  final AuthSession? session;
  final AppException? error;
  final Object? unexpectedError;
  final bool waitForCompletion;

  int loginCallCount = 0;

  String? lastUsername;
  String? lastPassword;

  Completer<void>? _loginCompleter;

  void complete() {
    final Completer<void>? completer = _loginCompleter;

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

      _loginCompleter = completer;

      await completer.future;
    }

    final Object? thrownUnexpectedError = unexpectedError;

    if (thrownUnexpectedError != null) {
      throw thrownUnexpectedError;
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
