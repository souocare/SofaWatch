import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/admin_users/application/cubit/admin_users_cubit.dart';
import 'package:sofawatch/features/admin_users/application/cubit/admin_users_state.dart';
import 'package:sofawatch/features/admin_users/domain/models/admin_user.dart';
import 'package:sofawatch/features/admin_users/domain/models/admin_users_summary.dart';
import 'package:sofawatch/features/admin_users/domain/models/password_recovery_link.dart';
import 'package:sofawatch/features/admin_users/domain/repositories/admin_users_repository.dart';

void main() {
  group('AdminUsersCubit', () {
    test('loads users', () async {
      final _FakeAdminUsersRepository repository = _FakeAdminUsersRepository();

      final AdminUsersCubit cubit = AdminUsersCubit(repository: repository);

      await cubit.load();

      expect(repository.listCalls, 1);

      final AdminUsersSuccess state = cubit.state as AdminUsersSuccess;

      expect(state.users, hasLength(2));
      expect(state.users.first.displayName, 'Administrator');
      expect(state.users.last.displayName, 'Regular User');

      await cubit.close();
    });

    test('preserves AppException on load failure', () async {
      final AdminUsersCubit cubit = AdminUsersCubit(
        repository: _FakeAdminUsersRepository(
          error: const AppException.connection(),
        ),
      );

      await cubit.load();

      final AdminUsersFailure state = cubit.state as AdminUsersFailure;

      expect(state.error.type, AppExceptionType.connection);

      await cubit.close();
    });

    test('maps unexpected failure to unknown', () async {
      final AdminUsersCubit cubit = AdminUsersCubit(
        repository: _FakeAdminUsersRepository(
          unexpectedError: StateError('boom'),
        ),
      );

      await cubit.load();

      final AdminUsersFailure state = cubit.state as AdminUsersFailure;

      expect(state.error.type, AppExceptionType.unknown);

      await cubit.close();
    });

    test('Retry repeats users request', () async {
      final _RetryAdminUsersRepository repository =
          _RetryAdminUsersRepository();

      final AdminUsersCubit cubit = AdminUsersCubit(repository: repository);

      await cubit.load();

      expect(repository.calls, 1);
      expect(cubit.state, isA<AdminUsersFailure>());

      await cubit.retry();

      expect(repository.calls, 2);
      expect(cubit.state, isA<AdminUsersSuccess>());

      await cubit.close();
    });
  });
}

const List<AdminUser> _users = <AdminUser>[
  AdminUser(
    id: 'admin-1',
    username: 'administrator',
    email: 'admin@example.com',
    displayName: 'Administrator',
    isActive: true,
    isAdmin: true,
  ),
  AdminUser(
    id: 'user-1',
    username: 'regular-user',
    email: 'regular@example.com',
    displayName: 'Regular User',
    isActive: true,
    isAdmin: false,
  ),
];

final class _FakeAdminUsersRepository implements AdminUsersRepository {
  _FakeAdminUsersRepository({this.error, this.unexpectedError});

  final AppException? error;
  final Object? unexpectedError;

  int listCalls = 0;

  @override
  Future<List<AdminUser>> listUsers() async {
    listCalls += 1;

    final AppException? appError = error;

    if (appError != null) {
      throw appError;
    }

    final Object? unknownError = unexpectedError;

    if (unknownError != null) {
      throw unknownError;
    }

    return _users;
  }

  @override
  Future<PasswordRecoveryLink> startPasswordRecovery({required String userId}) {
    throw UnimplementedError();
  }

  @override
  Future<AdminUsersSummary> getSummary() {
    throw UnimplementedError();
  }
}

final class _RetryAdminUsersRepository implements AdminUsersRepository {
  int calls = 0;

  @override
  Future<List<AdminUser>> listUsers() async {
    calls += 1;

    if (calls == 1) {
      throw const AppException.connection();
    }

    return _users;
  }

  @override
  Future<PasswordRecoveryLink> startPasswordRecovery({required String userId}) {
    throw UnimplementedError();
  }

  @override
  Future<AdminUsersSummary> getSummary() {
    throw UnimplementedError();
  }
}
