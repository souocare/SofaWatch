import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_entry_cubit.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_entry_state.dart';
import 'package:sofawatch/features/auth/domain/models/setup_status.dart';
import 'package:sofawatch/features/auth/domain/repositories/setup_status_repository.dart';

void main() {
  group('AuthEntryCubit', () {
    test('starts in initial state', () {
      final AuthEntryCubit cubit = AuthEntryCubit(
        repository: _FakeSetupStatusRepository(),
      );

      expect(cubit.state, const AuthEntryInitial());

      cubit.close();
    });

    test('emits setup required when installation has no users', () async {
      final AuthEntryCubit cubit = AuthEntryCubit(
        repository: _FakeSetupStatusRepository(
          status: const SetupStatus(setupRequired: true),
        ),
      );

      final Future<void> expectation = expectLater(
        cubit.stream,
        emitsInOrder(<AuthEntryState>[
          const AuthEntryChecking(),
          const AuthEntrySetupRequired(),
        ]),
      );

      await cubit.load();
      await expectation;

      expect(cubit.state, const AuthEntrySetupRequired());

      await cubit.close();
    });

    test('emits login required when setup is already completed', () async {
      final AuthEntryCubit cubit = AuthEntryCubit(
        repository: _FakeSetupStatusRepository(
          status: const SetupStatus(setupRequired: false),
        ),
      );

      final Future<void> expectation = expectLater(
        cubit.stream,
        emitsInOrder(<AuthEntryState>[
          const AuthEntryChecking(),
          const AuthEntryLoginRequired(),
        ]),
      );

      await cubit.load();
      await expectation;

      expect(cubit.state, const AuthEntryLoginRequired());

      await cubit.close();
    });

    test('emits failure when setup status request fails', () async {
      const AppException error = AppException.connection();

      final AuthEntryCubit cubit = AuthEntryCubit(
        repository: _FakeSetupStatusRepository(error: error),
      );

      final Future<void> expectation = expectLater(
        cubit.stream,
        emitsInOrder(<AuthEntryState>[
          const AuthEntryChecking(),
          const AuthEntryFailure(error),
        ]),
      );

      await cubit.load();
      await expectation;

      expect(cubit.state, const AuthEntryFailure(error));

      await cubit.close();
    });

    test('maps unexpected repository error to unknown failure', () async {
      final AuthEntryCubit cubit = AuthEntryCubit(
        repository: _FakeSetupStatusRepository(
          error: StateError('Unexpected setup status failure.'),
        ),
      );

      await cubit.load();

      expect(cubit.state, isA<AuthEntryFailure>());

      final AuthEntryFailure state = cubit.state as AuthEntryFailure;

      expect(state.error.type, AppExceptionType.unknown);

      await cubit.close();
    });

    test('retry repeats setup status resolution', () async {
      final _FakeSetupStatusRepository repository = _FakeSetupStatusRepository(
        status: const SetupStatus(setupRequired: false),
      );

      final AuthEntryCubit cubit = AuthEntryCubit(repository: repository);

      await cubit.load();
      await cubit.retry();

      expect(repository.callCount, 2);

      expect(cubit.state, const AuthEntryLoginRequired());

      await cubit.close();
    });
  });
}

final class _FakeSetupStatusRepository implements SetupStatusRepository {
  _FakeSetupStatusRepository({this.status, this.error});

  final SetupStatus? status;
  final Object? error;

  int callCount = 0;

  @override
  Future<SetupStatus> getStatus() async {
    callCount += 1;

    final Object? resolvedError = error;

    if (resolvedError != null) {
      throw resolvedError;
    }

    return status ?? const SetupStatus(setupRequired: false);
  }
}
