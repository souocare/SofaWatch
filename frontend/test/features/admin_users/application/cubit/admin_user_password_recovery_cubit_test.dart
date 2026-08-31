import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/admin_users/application/cubit/admin_user_password_recovery_cubit.dart';
import 'package:sofawatch/features/admin_users/application/cubit/admin_user_password_recovery_state.dart';
import 'package:sofawatch/features/admin_users/domain/models/admin_user.dart';
import 'package:sofawatch/features/admin_users/domain/models/admin_users_summary.dart';
import 'package:sofawatch/features/admin_users/domain/models/password_recovery_link.dart';
import 'package:sofawatch/features/admin_users/domain/repositories/admin_users_repository.dart';

void main() {
  group('AdminUserPasswordRecoveryCubit', () {
    test('starts password recovery', () async {
      final _FakeAdminUsersRepository repository = _FakeAdminUsersRepository();

      final AdminUserPasswordRecoveryCubit cubit =
          AdminUserPasswordRecoveryCubit(repository: repository);

      await cubit.start(userId: ' user-123 ');

      expect(repository.calls, 1);
      expect(repository.lastUserId, 'user-123');

      expect(cubit.state, isA<AdminUserPasswordRecoverySuccess>());

      final AdminUserPasswordRecoverySuccess state =
          cubit.state as AdminUserPasswordRecoverySuccess;

      expect(state.recovery.token, 'reset-token');

      await cubit.close();
    });

    test('prevents duplicate request while loading', () async {
      final _PendingAdminUsersRepository repository =
          _PendingAdminUsersRepository();

      final AdminUserPasswordRecoveryCubit cubit =
          AdminUserPasswordRecoveryCubit(repository: repository);

      final Future<void> first = cubit.start(userId: 'user-123');

      await Future<void>.delayed(Duration.zero);

      final Future<void> second = cubit.start(userId: 'user-123');

      expect(repository.calls, 1);

      repository.complete();

      await Future.wait(<Future<void>>[first, second]);

      expect(repository.calls, 1);

      await cubit.close();
    });

    test('preserves AppException failure', () async {
      final AdminUserPasswordRecoveryCubit cubit =
          AdminUserPasswordRecoveryCubit(
            repository: _FakeAdminUsersRepository(
              error: const AppException(
                type: AppExceptionType.notFound,
                message: 'User not found.',
                code: 'user_not_found',
                statusCode: 404,
              ),
            ),
          );

      await cubit.start(userId: 'user-404');

      final AdminUserPasswordRecoveryFailure state =
          cubit.state as AdminUserPasswordRecoveryFailure;

      expect(state.error.code, 'user_not_found');

      await cubit.close();
    });

    test('maps unexpected failure to unknown', () async {
      final AdminUserPasswordRecoveryCubit cubit =
          AdminUserPasswordRecoveryCubit(
            repository: _FakeAdminUsersRepository(
              unexpectedError: StateError('boom'),
            ),
          );

      await cubit.start(userId: 'user-123');

      final AdminUserPasswordRecoveryFailure state =
          cubit.state as AdminUserPasswordRecoveryFailure;

      expect(state.error.type, AppExceptionType.unknown);

      await cubit.close();
    });

    test('reset returns to initial state', () async {
      final AdminUserPasswordRecoveryCubit cubit =
          AdminUserPasswordRecoveryCubit(
            repository: _FakeAdminUsersRepository(),
          );

      await cubit.start(userId: 'user-123');

      expect(cubit.state, isA<AdminUserPasswordRecoverySuccess>());

      cubit.reset();

      expect(cubit.state, isA<AdminUserPasswordRecoveryInitial>());

      await cubit.close();
    });
  });
}

final PasswordRecoveryLink _recovery = PasswordRecoveryLink(
  token: 'reset-token',
  expiresAt: DateTime.utc(2026, 8, 26, 10),
);

final class _FakeAdminUsersRepository implements AdminUsersRepository {
  _FakeAdminUsersRepository({this.error, this.unexpectedError});

  final AppException? error;
  final Object? unexpectedError;

  int calls = 0;
  String? lastUserId;

  @override
  Future<PasswordRecoveryLink> startPasswordRecovery({
    required String userId,
  }) async {
    calls += 1;
    lastUserId = userId;

    final AppException? appError = error;

    if (appError != null) {
      throw appError;
    }

    final Object? unknownError = unexpectedError;

    if (unknownError != null) {
      throw unknownError;
    }

    return _recovery;
  }

  @override
  Future<List<AdminUser>> listUsers() {
    throw UnimplementedError(
      'listUsers is not used by password recovery cubit tests.',
    );
  }

  @override
  Future<AdminUsersSummary> getSummary() {
    throw UnimplementedError();
  }
}

final class _PendingAdminUsersRepository implements AdminUsersRepository {
  final Completer<PasswordRecoveryLink> _completer =
      Completer<PasswordRecoveryLink>();

  int calls = 0;

  void complete() {
    _completer.complete(_recovery);
  }

  @override
  Future<PasswordRecoveryLink> startPasswordRecovery({required String userId}) {
    calls += 1;

    return _completer.future;
  }

  @override
  Future<List<AdminUser>> listUsers() {
    throw UnimplementedError(
      'listUsers is not used by password recovery cubit tests.',
    );
  }

  @override
  Future<AdminUsersSummary> getSummary() {
    throw UnimplementedError();
  }
}
