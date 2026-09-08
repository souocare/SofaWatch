import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/application/cubit/initial_setup_cubit.dart';
import 'package:sofawatch/features/auth/application/cubit/initial_setup_state.dart';
import 'package:sofawatch/features/auth/domain/models/auth_session.dart';
import 'package:sofawatch/features/auth/domain/repositories/auth_repository.dart';

void main() {
  group('InitialSetupCubit', () {
    test('starts in InitialSetupInitial', () async {
      final InitialSetupCubit cubit = InitialSetupCubit(
        repository: _FakeAuthRepository(),
      );

      expect(cubit.state, const InitialSetupInitial());

      await cubit.close();
    });

    test('validates required fields', () async {
      final _FakeAuthRepository repository = _FakeAuthRepository();

      final InitialSetupCubit cubit = InitialSetupCubit(repository: repository);

      await cubit.submit(
        displayName: '   ',
        username: '   ',
        email: '',
        password: '',
        confirmPassword: '',
      );

      expect(
        cubit.state,
        const InitialSetupValidationFailure(
          displayNameError: 'Enter your display name.',
          usernameError: 'Enter a username.',
          passwordError: 'Enter a password.',
          confirmPasswordError: 'Confirm your password.',
        ),
      );

      expect(repository.initialSetupCalls, 0);

      await cubit.close();
    });

    test('validates username rules', () async {
      final InitialSetupCubit cubit = InitialSetupCubit(
        repository: _FakeAuthRepository(),
      );

      await cubit.submit(
        displayName: 'Gonçalo',
        username: 'ab',
        email: '',
        password: 'correct-password',
        confirmPassword: 'correct-password',
      );

      expect(
        (cubit.state as InitialSetupValidationFailure).usernameError,
        'Username must contain at least 3 characters.',
      );

      await cubit.submit(
        displayName: 'Gonçalo',
        username: 'user name',
        email: '',
        password: 'correct-password',
        confirmPassword: 'correct-password',
      );

      expect(
        (cubit.state as InitialSetupValidationFailure).usernameError,
        'Use only letters, numbers, periods, underscores, or hyphens.',
      );

      await cubit.submit(
        displayName: 'Gonçalo',
        username: 'a' * 33,
        email: '',
        password: 'correct-password',
        confirmPassword: 'correct-password',
      );

      expect(
        (cubit.state as InitialSetupValidationFailure).usernameError,
        'Username cannot exceed 32 characters.',
      );

      await cubit.close();
    });

    test('validates optional email only when provided', () async {
      final InitialSetupCubit cubit = InitialSetupCubit(
        repository: _FakeAuthRepository(),
      );

      await cubit.submit(
        displayName: 'Gonçalo',
        username: 'souocare',
        email: 'invalid-email',
        password: 'correct-password',
        confirmPassword: 'correct-password',
      );

      expect(
        (cubit.state as InitialSetupValidationFailure).emailError,
        'Enter a valid email address.',
      );

      await cubit.close();
    });

    test('validates password length', () async {
      final InitialSetupCubit cubit = InitialSetupCubit(
        repository: _FakeAuthRepository(),
      );

      await cubit.submit(
        displayName: 'Gonçalo',
        username: 'souocare',
        email: '',
        password: 'short',
        confirmPassword: 'short',
      );

      expect(
        (cubit.state as InitialSetupValidationFailure).passwordError,
        'Password must contain at least 8 characters.',
      );

      final String longPassword = 'a' * 129;

      await cubit.submit(
        displayName: 'Gonçalo',
        username: 'souocare',
        email: '',
        password: longPassword,
        confirmPassword: longPassword,
      );

      expect(
        (cubit.state as InitialSetupValidationFailure).passwordError,
        'Password cannot exceed 128 characters.',
      );

      await cubit.close();
    });

    test('validates password confirmation', () async {
      final InitialSetupCubit cubit = InitialSetupCubit(
        repository: _FakeAuthRepository(),
      );

      await cubit.submit(
        displayName: 'Gonçalo',
        username: 'souocare',
        email: '',
        password: 'correct-password',
        confirmPassword: 'different-password',
      );

      expect(
        (cubit.state as InitialSetupValidationFailure).confirmPasswordError,
        'Passwords do not match.',
      );

      await cubit.close();
    });

    test('normalizes values and emits success', () async {
      final _FakeAuthRepository repository = _FakeAuthRepository();

      final InitialSetupCubit cubit = InitialSetupCubit(repository: repository);

      final Future<void> expectation = expectLater(
        cubit.stream,
        emitsInOrder(<InitialSetupState>[
          const InitialSetupSubmitting(),
          const InitialSetupSuccess(_session),
        ]),
      );

      await cubit.submit(
        displayName: '  Gonçalo  ',
        username: '  souocare  ',
        email: '  goncalo@example.com  ',
        password: 'correct-password',
        confirmPassword: 'correct-password',
      );

      await expectation;

      expect(repository.initialSetupCalls, 1);
      expect(repository.lastDisplayName, 'Gonçalo');
      expect(repository.lastUsername, 'souocare');
      expect(repository.lastEmail, 'goncalo@example.com');
      expect(repository.lastPassword, 'correct-password');

      await cubit.close();
    });

    test('converts blank optional email to null', () async {
      final _FakeAuthRepository repository = _FakeAuthRepository();

      final InitialSetupCubit cubit = InitialSetupCubit(repository: repository);

      await cubit.submit(
        displayName: 'Gonçalo',
        username: 'souocare',
        email: '   ',
        password: 'correct-password',
        confirmPassword: 'correct-password',
      );

      expect(repository.lastEmail, isNull);

      await cubit.close();
    });

    test('maps completed setup conflict to dedicated state', () async {
      final _FakeAuthRepository repository = _FakeAuthRepository(
        error: const AppException(
          type: AppExceptionType.conflict,
          code: 'initial_setup_completed',
          statusCode: 409,
          message: 'Initial SofaWatch setup has already been completed.',
        ),
      );

      final InitialSetupCubit cubit = InitialSetupCubit(repository: repository);

      await cubit.submit(
        displayName: 'Gonçalo',
        username: 'souocare',
        email: '',
        password: 'correct-password',
        confirmPassword: 'correct-password',
      );

      expect(cubit.state, const InitialSetupAlreadyCompleted());

      await cubit.close();
    });

    test('preserves application failure', () async {
      const AppException error = AppException.connection();

      final InitialSetupCubit cubit = InitialSetupCubit(
        repository: _FakeAuthRepository(error: error),
      );

      await cubit.submit(
        displayName: 'Gonçalo',
        username: 'souocare',
        email: '',
        password: 'correct-password',
        confirmPassword: 'correct-password',
      );

      expect(cubit.state, const InitialSetupFailure(error));

      await cubit.close();
    });

    test('maps unexpected failure to unknown', () async {
      final InitialSetupCubit cubit = InitialSetupCubit(
        repository: _FakeAuthRepository(
          unexpectedError: StateError('Unexpected setup failure.'),
        ),
      );

      await cubit.submit(
        displayName: 'Gonçalo',
        username: 'souocare',
        email: '',
        password: 'correct-password',
        confirmPassword: 'correct-password',
      );

      final InitialSetupFailure state = cubit.state as InitialSetupFailure;

      expect(state.error.type, AppExceptionType.unknown);

      await cubit.close();
    });

    test('ignores another submit while setup is in progress', () async {
      final _FakeAuthRepository repository = _FakeAuthRepository(
        waitForCompletion: true,
      );

      final InitialSetupCubit cubit = InitialSetupCubit(repository: repository);

      final Future<void> firstSubmit = cubit.submit(
        displayName: 'Gonçalo',
        username: 'souocare',
        email: '',
        password: 'correct-password',
        confirmPassword: 'correct-password',
      );

      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, const InitialSetupSubmitting());

      await cubit.submit(
        displayName: 'Another User',
        username: 'another-user',
        email: '',
        password: 'another-password',
        confirmPassword: 'another-password',
      );

      expect(repository.initialSetupCalls, 1);

      repository.complete();

      await firstSubmit;

      expect(cubit.state, const InitialSetupSuccess(_session));

      await cubit.close();
    });

    test('clearFeedback returns to initial state', () async {
      final InitialSetupCubit cubit = InitialSetupCubit(
        repository: _FakeAuthRepository(),
      );

      await cubit.submit(
        displayName: '',
        username: '',
        email: '',
        password: '',
        confirmPassword: '',
      );

      expect(cubit.state, isA<InitialSetupValidationFailure>());

      cubit.clearFeedback();

      expect(cubit.state, const InitialSetupInitial());

      await cubit.close();
    });
  });
}

const AuthSession _session = AuthSession(
  accessToken: 'setup-access-token',
  expiresIn: Duration(minutes: 15),
);

final class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.error,
    this.unexpectedError,
    this.waitForCompletion = false,
  });

  final AppException? error;
  final Object? unexpectedError;
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

    final Object? thrownUnexpectedError = unexpectedError;

    if (thrownUnexpectedError != null) {
      throw thrownUnexpectedError;
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
