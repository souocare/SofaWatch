import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/application/cubit/password_recovery_cubit.dart';
import 'package:sofawatch/features/auth/application/cubit/password_recovery_state.dart';
import 'package:sofawatch/features/auth/domain/repositories/password_recovery_repository.dart';

void main() {
  group('PasswordRecoveryCubit', () {
    test('rejects missing token', () async {
      final _FakePasswordRecoveryRepository repository =
          _FakePasswordRecoveryRepository();

      final PasswordRecoveryCubit cubit = PasswordRecoveryCubit(
        repository: repository,
      );

      await cubit.submit(
        token: null,
        newPassword: 'new-password',
        confirmPassword: 'new-password',
      );

      expect(cubit.state, isA<PasswordRecoveryInvalid>());
      expect(repository.completeCalls, 0);

      await cubit.close();
    });

    test('validates empty new password', () async {
      final PasswordRecoveryCubit cubit = PasswordRecoveryCubit(
        repository: _FakePasswordRecoveryRepository(),
      );

      await cubit.submit(
        token: 'reset-token',
        newPassword: '',
        confirmPassword: '',
      );

      final PasswordRecoveryValidationFailure state =
          cubit.state as PasswordRecoveryValidationFailure;

      expect(state.newPasswordError, 'Enter a new password.');

      expect(state.confirmPasswordError, 'Confirm your new password.');

      await cubit.close();
    });

    test('rejects password shorter than eight characters', () async {
      final PasswordRecoveryCubit cubit = PasswordRecoveryCubit(
        repository: _FakePasswordRecoveryRepository(),
      );

      await cubit.submit(
        token: 'reset-token',
        newPassword: 'short',
        confirmPassword: 'short',
      );

      final PasswordRecoveryValidationFailure state =
          cubit.state as PasswordRecoveryValidationFailure;

      expect(state.newPasswordError, 'Password must be at least 8 characters.');

      await cubit.close();
    });

    test('rejects mismatched confirmation', () async {
      final PasswordRecoveryCubit cubit = PasswordRecoveryCubit(
        repository: _FakePasswordRecoveryRepository(),
      );

      await cubit.submit(
        token: 'reset-token',
        newPassword: 'new-password',
        confirmPassword: 'different-password',
      );

      final PasswordRecoveryValidationFailure state =
          cubit.state as PasswordRecoveryValidationFailure;

      expect(state.confirmPasswordError, 'Passwords do not match.');

      await cubit.close();
    });

    test('completes password recovery', () async {
      final _FakePasswordRecoveryRepository repository =
          _FakePasswordRecoveryRepository();

      final PasswordRecoveryCubit cubit = PasswordRecoveryCubit(
        repository: repository,
      );

      await cubit.submit(
        token: ' reset-token ',
        newPassword: 'new-password',
        confirmPassword: 'new-password',
      );

      expect(repository.completeCalls, 1);
      expect(repository.lastToken, 'reset-token');
      expect(repository.lastNewPassword, 'new-password');

      expect(cubit.state, isA<PasswordRecoverySuccess>());

      await cubit.close();
    });

    test('maps invalid recovery token to invalid state', () async {
      final PasswordRecoveryCubit cubit = PasswordRecoveryCubit(
        repository: _FakePasswordRecoveryRepository(
          error: const AppException(
            type: AppExceptionType.badResponse,
            message: 'Invalid recovery token.',
            code: 'password_recovery_invalid',
            statusCode: 400,
          ),
        ),
      );

      await cubit.submit(
        token: 'reset-token',
        newPassword: 'new-password',
        confirmPassword: 'new-password',
      );

      expect(cubit.state, isA<PasswordRecoveryInvalid>());

      await cubit.close();
    });

    test('preserves other AppException failures', () async {
      final PasswordRecoveryCubit cubit = PasswordRecoveryCubit(
        repository: _FakePasswordRecoveryRepository(
          error: const AppException.connection(),
        ),
      );

      await cubit.submit(
        token: 'reset-token',
        newPassword: 'new-password',
        confirmPassword: 'new-password',
      );

      final PasswordRecoveryFailure state =
          cubit.state as PasswordRecoveryFailure;

      expect(state.error.type, AppExceptionType.connection);

      await cubit.close();
    });

    test('maps unexpected failures to unknown', () async {
      final PasswordRecoveryCubit cubit = PasswordRecoveryCubit(
        repository: _FakePasswordRecoveryRepository(
          unexpectedError: StateError('boom'),
        ),
      );

      await cubit.submit(
        token: 'reset-token',
        newPassword: 'new-password',
        confirmPassword: 'new-password',
      );

      final PasswordRecoveryFailure state =
          cubit.state as PasswordRecoveryFailure;

      expect(state.error.type, AppExceptionType.unknown);

      await cubit.close();
    });

    test('clearFeedback resets validation failure', () async {
      final PasswordRecoveryCubit cubit = PasswordRecoveryCubit(
        repository: _FakePasswordRecoveryRepository(),
      );

      await cubit.submit(
        token: 'reset-token',
        newPassword: '',
        confirmPassword: '',
      );

      expect(cubit.state, isA<PasswordRecoveryValidationFailure>());

      cubit.clearFeedback();

      expect(cubit.state, isA<PasswordRecoveryInitial>());

      await cubit.close();
    });

    test('clearFeedback keeps invalid token state', () async {
      final PasswordRecoveryCubit cubit = PasswordRecoveryCubit(
        repository: _FakePasswordRecoveryRepository(),
      );

      await cubit.submit(
        token: null,
        newPassword: 'new-password',
        confirmPassword: 'new-password',
      );

      cubit.clearFeedback();

      expect(cubit.state, isA<PasswordRecoveryInvalid>());

      await cubit.close();
    });
  });
}

final class _FakePasswordRecoveryRepository
    implements PasswordRecoveryRepository {
  _FakePasswordRecoveryRepository({this.error, this.unexpectedError});

  final AppException? error;
  final Object? unexpectedError;

  int completeCalls = 0;

  String? lastToken;
  String? lastNewPassword;

  @override
  Future<void> complete({
    required String token,
    required String newPassword,
  }) async {
    completeCalls += 1;

    lastToken = token;
    lastNewPassword = newPassword;

    final AppException? appError = error;

    if (appError != null) {
      throw appError;
    }

    final Object? unknownError = unexpectedError;

    if (unknownError != null) {
      throw unknownError;
    }
  }
}
