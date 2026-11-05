import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/application/cubit/registration_cubit.dart';
import 'package:sofawatch/features/auth/application/cubit/registration_state.dart';
import 'package:sofawatch/features/auth/domain/models/auth_session.dart';
import 'package:sofawatch/features/auth/domain/repositories/registration_repository.dart';

void main() {
  group('RegistrationCubit', () {
    test('starts in RegistrationInitial', () async {
      final RegistrationCubit cubit = RegistrationCubit(
        repository: _FakeRegistrationRepository(),
      );

      expect(cubit.state, const RegistrationInitial());

      await cubit.close();
    });

    test('loads open registration availability', () async {
      final RegistrationCubit cubit = RegistrationCubit(
        repository: _FakeRegistrationRepository(isOpen: true),
      );

      await cubit.loadAvailability();

      expect(cubit.state, const RegistrationOpen());

      await cubit.close();
    });

    test('loads closed registration availability', () async {
      final RegistrationCubit cubit = RegistrationCubit(
        repository: _FakeRegistrationRepository(isOpen: false),
      );

      await cubit.loadAvailability();

      expect(cubit.state, const RegistrationClosed());

      await cubit.close();
    });

    test('does not submit before checking availability', () async {
      final _FakeRegistrationRepository repository =
          _FakeRegistrationRepository();

      final RegistrationCubit cubit = RegistrationCubit(repository: repository);

      await cubit.submit(
        username: 'newuser',
        displayName: 'New User',
        password: 'secure-password',
        confirmPassword: 'secure-password',
      );

      expect(repository.registerCalls, 0);

      await cubit.close();
    });

    test('does not submit when registration is closed', () async {
      final _FakeRegistrationRepository repository =
          _FakeRegistrationRepository(isOpen: false);

      final RegistrationCubit cubit = RegistrationCubit(repository: repository);

      await cubit.loadAvailability();

      await cubit.submit(
        username: 'newuser',
        displayName: 'New User',
        password: 'secure-password',
        confirmPassword: 'secure-password',
      );

      expect(repository.registerCalls, 0);

      await cubit.close();
    });

    test('validates username and display name', () async {
      final RegistrationCubit cubit = RegistrationCubit(
        repository: _FakeRegistrationRepository(),
      );

      await cubit.loadAvailability();

      await cubit.submit(
        username: 'invalid username',
        displayName: ' ',
        password: 'secure-password',
        confirmPassword: 'secure-password',
      );

      expect(cubit.state, isA<RegistrationValidationFailure>());

      final RegistrationValidationFailure state =
          cubit.state as RegistrationValidationFailure;

      expect(state.usernameError, isNotNull);
      expect(state.displayNameError, isNotNull);

      await cubit.close();
    });

    test('validates password confirmation', () async {
      final _FakeRegistrationRepository repository =
          _FakeRegistrationRepository();

      final RegistrationCubit cubit = RegistrationCubit(repository: repository);

      await cubit.loadAvailability();

      await cubit.submit(
        username: 'newuser',
        displayName: 'New User',
        password: 'secure-password',
        confirmPassword: 'different-password',
      );

      final RegistrationValidationFailure state =
          cubit.state as RegistrationValidationFailure;

      expect(state.confirmPasswordError, 'Passwords do not match.');
      expect(repository.registerCalls, 0);

      await cubit.close();
    });

    test('registers successfully and normalizes values', () async {
      final _FakeRegistrationRepository repository =
          _FakeRegistrationRepository();

      final RegistrationCubit cubit = RegistrationCubit(repository: repository);

      await cubit.loadAvailability();

      await cubit.submit(
        username: '  newuser  ',
        displayName: '  New User  ',
        email: '  new@example.com  ',
        password: 'secure-password',
        confirmPassword: 'secure-password',
      );

      expect(cubit.state, const RegistrationSuccess(_session));
      expect(repository.registerCalls, 1);
      expect(repository.lastUsername, 'newuser');
      expect(repository.lastDisplayName, 'New User');
      expect(repository.lastEmail, 'new@example.com');

      await cubit.close();
    });

    test('prevents duplicate submissions', () async {
      final _FakeRegistrationRepository repository =
          _FakeRegistrationRepository(waitForCompletion: true);

      final RegistrationCubit cubit = RegistrationCubit(repository: repository);

      await cubit.loadAvailability();

      final Future<void> firstSubmission = cubit.submit(
        username: 'newuser',
        displayName: 'New User',
        password: 'secure-password',
        confirmPassword: 'secure-password',
      );

      expect(cubit.state, const RegistrationSubmitting());

      await cubit.submit(
        username: 'newuser',
        displayName: 'New User',
        password: 'secure-password',
        confirmPassword: 'secure-password',
      );

      expect(repository.registerCalls, 1);

      repository.complete();

      await firstSubmission;

      expect(cubit.state, const RegistrationSuccess(_session));

      await cubit.close();
    });

    test('closes registration after backend rejects it', () async {
      final _FakeRegistrationRepository repository =
          _FakeRegistrationRepository(
            error: const AppException(
              type: AppExceptionType.forbidden,
              code: 'registration_closed',
              statusCode: 403,
              message: 'Account registration is currently closed.',
            ),
          );

      final RegistrationCubit cubit = RegistrationCubit(repository: repository);

      await cubit.loadAvailability();

      await cubit.submit(
        username: 'newuser',
        displayName: 'New User',
        password: 'secure-password',
        confirmPassword: 'secure-password',
      );

      expect(cubit.state, const RegistrationClosed());

      await cubit.close();
    });
  });
}

const AuthSession _session = AuthSession(
  accessToken: 'registered-token',
  expiresIn: Duration(minutes: 15),
);

final class _FakeRegistrationRepository implements RegistrationRepository {
  _FakeRegistrationRepository({
    this.isOpen = true,
    this.error,
    this.waitForCompletion = false,
  });

  final bool isOpen;
  final AppException? error;
  final bool waitForCompletion;

  int registerCalls = 0;

  String? lastUsername;
  String? lastDisplayName;
  String? lastEmail;

  Completer<void>? _completer;

  @override
  Future<bool> isRegistrationOpen() async {
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

    lastUsername = username;
    lastDisplayName = displayName;
    lastEmail = email;

    if (waitForCompletion) {
      _completer = Completer<void>();
      await _completer!.future;
    }

    if (error != null) {
      throw error!;
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
