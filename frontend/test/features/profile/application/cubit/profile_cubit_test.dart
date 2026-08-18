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
  });
}

const ProfileUser _user = ProfileUser(
  id: '11111111-2222-3333-4444-555555555555',
  displayName: 'Gonçalo',
  isLocal: true,
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
}
