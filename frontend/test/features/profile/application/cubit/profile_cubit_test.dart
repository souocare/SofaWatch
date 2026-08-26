import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/profile/application/cubit/profile_cubit.dart';
import 'package:sofawatch/features/profile/application/cubit/profile_state.dart';
import 'package:sofawatch/features/profile/domain/models/profile_user.dart';
import 'package:sofawatch/features/profile/domain/repositories/profile_repository.dart';

void main() {
  group('ProfileCubit', () {
    test('loads current user', () async {
      final ProfileCubit cubit = ProfileCubit(
        repository: _FakeProfileRepository(),
      );

      await cubit.load();

      expect(cubit.state, isA<ProfileSuccess>());

      final ProfileSuccess state = cubit.state as ProfileSuccess;

      expect(state.user.displayName, 'Gonçalo');

      await cubit.close();
    });

    test('preserves AppException when loading fails', () async {
      final ProfileCubit cubit = ProfileCubit(
        repository: _FakeProfileRepository(
          error: const AppException.connection(),
        ),
      );

      await cubit.load();

      expect(cubit.state, isA<ProfileFailure>());

      final ProfileFailure state = cubit.state as ProfileFailure;

      expect(state.error.type, AppExceptionType.connection);

      await cubit.close();
    });

    test('maps unexpected errors to unknown', () async {
      final ProfileCubit cubit = ProfileCubit(
        repository: _FakeProfileRepository(unexpectedError: StateError('boom')),
      );

      await cubit.load();

      final ProfileFailure state = cubit.state as ProfileFailure;

      expect(state.error.type, AppExceptionType.unknown);

      await cubit.close();
    });

    test('Retry repeats the current user request', () async {
      final _RetryProfileRepository repository = _RetryProfileRepository();

      final ProfileCubit cubit = ProfileCubit(repository: repository);

      await cubit.load();

      expect(repository.calls, 1);
      expect(cubit.state, isA<ProfileFailure>());

      await cubit.retry();

      expect(repository.calls, 2);
      expect(cubit.state, isA<ProfileSuccess>());

      await cubit.close();
    });
    test(
      'updates display name while preserving Profile success state',
      () async {
        final _UpdatingProfileRepository repository =
            _UpdatingProfileRepository();

        final ProfileCubit cubit = ProfileCubit(repository: repository);

        await cubit.load();

        await cubit.updateDisplayName('Novo Nome');

        expect(repository.updateDisplayNameCalls, 1);
        expect(repository.lastDisplayName, 'Novo Nome');

        final ProfileSuccess state = cubit.state as ProfileSuccess;

        expect(state.user.displayName, 'Novo Nome');
        expect(state.isUpdatingDisplayName, isFalse);
        expect(state.updateDisplayNameError, isNull);

        await cubit.close();
      },
    );

    test('keeps previous user when display name update fails', () async {
      final ProfileCubit cubit = ProfileCubit(
        repository: _UpdatingProfileRepository(
          updateError: const AppException.connection(),
        ),
      );

      await cubit.load();

      final bool updated = await cubit.updateDisplayName('Novo Nome');

      expect(updated, isFalse);

      final ProfileSuccess state = cubit.state as ProfileSuccess;

      expect(state.user.displayName, 'Gonçalo');
      expect(state.isUpdatingDisplayName, isFalse);
      expect(state.updateDisplayNameError?.type, AppExceptionType.connection);

      await cubit.close();
    });

    test('does not update display name when value is unchanged', () async {
      final _UpdatingProfileRepository repository =
          _UpdatingProfileRepository();

      final ProfileCubit cubit = ProfileCubit(repository: repository);

      await cubit.load();

      final bool updated = await cubit.updateDisplayName('  Gonçalo  ');

      expect(updated, isFalse);
      expect(repository.updateDisplayNameCalls, 0);

      await cubit.close();
    });
    test('updates password', () async {
      final _PasswordProfileRepository repository =
          _PasswordProfileRepository();

      final ProfileCubit cubit = ProfileCubit(repository: repository);

      await cubit.load();

      final bool updated = await cubit.updatePassword(
        currentPassword: 'old-password',
        newPassword: 'new-password',
      );

      expect(updated, isTrue);
      expect(repository.currentPassword, 'old-password');
      expect(repository.newPassword, 'new-password');

      final ProfileSuccess state = cubit.state as ProfileSuccess;

      expect(state.isUpdatingPassword, isFalse);
      expect(state.updatePasswordError, isNull);

      await cubit.close();
    });

    test('preserves AppException when password update fails', () async {
      final _PasswordProfileRepository repository = _PasswordProfileRepository(
        error: const AppException(
          type: AppExceptionType.badResponse,
          code: 'current_password_invalid',
          message: 'The current password is incorrect.',
          statusCode: 400,
        ),
      );

      final ProfileCubit cubit = ProfileCubit(repository: repository);

      await cubit.load();

      final bool updated = await cubit.updatePassword(
        currentPassword: 'wrong-password',
        newPassword: 'new-password',
      );

      expect(updated, isFalse);

      final ProfileSuccess state = cubit.state as ProfileSuccess;

      expect(state.updatePasswordError?.type, AppExceptionType.badResponse);
      expect(state.updatePasswordError?.code, 'current_password_invalid');
      expect(state.updatePasswordError?.statusCode, 400);

      await cubit.close();
    });

    test('does not submit invalid new password', () async {
      final _PasswordProfileRepository repository =
          _PasswordProfileRepository();

      final ProfileCubit cubit = ProfileCubit(repository: repository);

      await cubit.load();

      final bool updated = await cubit.updatePassword(
        currentPassword: 'old-password',
        newPassword: 'short',
      );

      expect(updated, isFalse);
      expect(repository.passwordUpdateCalls, 0);

      await cubit.close();
    });
  });
}

const ProfileUser _user = ProfileUser(
  id: '11111111-2222-3333-4444-555555555555',
  username: 'souocare',
  email: 'goncalo@example.com',
  displayName: 'Gonçalo',
  isAdmin: true,
);

final class _FakeProfileRepository implements ProfileRepository {
  const _FakeProfileRepository({this.error, this.unexpectedError});

  final AppException? error;
  final Object? unexpectedError;

  @override
  Future<ProfileUser> getCurrentUser() async {
    final AppException? appError = error;

    if (appError != null) {
      throw appError;
    }

    final Object? unknownError = unexpectedError;

    if (unknownError != null) {
      throw unknownError;
    }

    return _user;
  }

  @override
  Future<ProfileUser> updateDisplayName({required String displayName}) async {
    return _user.copyWith(displayName: displayName);
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}
}

final class _RetryProfileRepository implements ProfileRepository {
  int calls = 0;

  @override
  Future<ProfileUser> getCurrentUser() async {
    calls++;

    if (calls == 1) {
      throw const AppException.connection();
    }

    return _user;
  }

  @override
  Future<ProfileUser> updateDisplayName({required String displayName}) async {
    return _user.copyWith(displayName: displayName);
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}
}

final class _UpdatingProfileRepository implements ProfileRepository {
  _UpdatingProfileRepository({this.updateError});

  final AppException? updateError;

  int updateDisplayNameCalls = 0;
  String? lastDisplayName;

  @override
  Future<ProfileUser> getCurrentUser() async {
    return _user;
  }

  @override
  Future<ProfileUser> updateDisplayName({required String displayName}) async {
    updateDisplayNameCalls++;
    lastDisplayName = displayName;

    final AppException? failure = updateError;

    if (failure != null) {
      throw failure;
    }

    return _user.copyWith(displayName: displayName);
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}
}

final class _PasswordProfileRepository implements ProfileRepository {
  _PasswordProfileRepository({this.error});

  final AppException? error;

  String? currentPassword;
  String? newPassword;
  int passwordUpdateCalls = 0;

  @override
  Future<ProfileUser> getCurrentUser() async {
    return _user;
  }

  @override
  Future<ProfileUser> updateDisplayName({required String displayName}) async {
    return _user.copyWith(displayName: displayName);
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    passwordUpdateCalls++;

    this.currentPassword = currentPassword;
    this.newPassword = newPassword;

    final AppException? failure = error;

    if (failure != null) {
      throw failure;
    }
  }
}
