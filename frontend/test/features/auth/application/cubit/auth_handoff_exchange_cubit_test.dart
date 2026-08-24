import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_handoff_exchange_cubit.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_handoff_exchange_state.dart';
import 'package:sofawatch/features/auth/domain/models/auth_handoff.dart';
import 'package:sofawatch/features/auth/domain/models/auth_session.dart';
import 'package:sofawatch/features/auth/domain/repositories/auth_handoff_repository.dart';

void main() {
  group('AuthHandoffExchangeCubit', () {
    test('starts in initial state', () async {
      final AuthHandoffExchangeCubit cubit = AuthHandoffExchangeCubit(
        repository: _FakeAuthHandoffRepository(),
      );

      expect(cubit.state, const AuthHandoffExchangeInitial());

      await cubit.close();
    });

    test('exchanges a valid handoff', () async {
      final _FakeAuthHandoffRepository repository = _FakeAuthHandoffRepository(
        session: _session,
      );

      final AuthHandoffExchangeCubit cubit = AuthHandoffExchangeCubit(
        repository: repository,
      );

      final Future<void> expectation = expectLater(
        cubit.stream,
        emitsInOrder(<AuthHandoffExchangeState>[
          const AuthHandoffExchangeLoading(),
          const AuthHandoffExchangeSuccess(_session),
        ]),
      );

      await cubit.exchange('handoff-token');

      await expectation;

      expect(repository.exchangeCalls, 1);
      expect(repository.lastToken, 'handoff-token');

      await cubit.close();
    });

    test('normalizes handoff token before exchange', () async {
      final _FakeAuthHandoffRepository repository = _FakeAuthHandoffRepository(
        session: _session,
      );

      final AuthHandoffExchangeCubit cubit = AuthHandoffExchangeCubit(
        repository: repository,
      );

      await cubit.exchange('  handoff-token  ');

      expect(repository.lastToken, 'handoff-token');

      await cubit.close();
    });

    test('rejects missing handoff without repository call', () async {
      final _FakeAuthHandoffRepository repository =
          _FakeAuthHandoffRepository();

      final AuthHandoffExchangeCubit cubit = AuthHandoffExchangeCubit(
        repository: repository,
      );

      await cubit.exchange(null);

      expect(cubit.state, const AuthHandoffExchangeInvalid());

      expect(repository.exchangeCalls, 0);

      await cubit.close();
    });

    test('rejects blank handoff without repository call', () async {
      final _FakeAuthHandoffRepository repository =
          _FakeAuthHandoffRepository();

      final AuthHandoffExchangeCubit cubit = AuthHandoffExchangeCubit(
        repository: repository,
      );

      await cubit.exchange('   ');

      expect(cubit.state, const AuthHandoffExchangeInvalid());

      expect(repository.exchangeCalls, 0);

      await cubit.close();
    });

    test('maps invalid handoff to invalid state', () async {
      const AppException error = AppException(
        type: AppExceptionType.unauthorized,
        code: 'invalid_auth_handoff',
        statusCode: 401,
        message: 'The authentication handoff is invalid or expired.',
      );

      final AuthHandoffExchangeCubit cubit = AuthHandoffExchangeCubit(
        repository: _FakeAuthHandoffRepository(error: error),
      );

      await cubit.exchange('handoff-token');

      expect(cubit.state, const AuthHandoffExchangeInvalid());

      await cubit.close();
    });

    test('emits failure for another AppException', () async {
      const AppException error = AppException.connection();

      final AuthHandoffExchangeCubit cubit = AuthHandoffExchangeCubit(
        repository: _FakeAuthHandoffRepository(error: error),
      );

      await cubit.exchange('handoff-token');

      expect(cubit.state, const AuthHandoffExchangeFailure(error));

      await cubit.close();
    });

    test('maps unexpected error to unknown failure', () async {
      final AuthHandoffExchangeCubit cubit = AuthHandoffExchangeCubit(
        repository: _FakeAuthHandoffRepository(
          error: StateError('Unexpected failure.'),
        ),
      );

      await cubit.exchange('handoff-token');

      expect(cubit.state, isA<AuthHandoffExchangeFailure>());

      final AuthHandoffExchangeFailure state =
          cubit.state as AuthHandoffExchangeFailure;

      expect(state.error.type, AppExceptionType.unknown);

      await cubit.close();
    });

    test('retries the previous handoff', () async {
      final _FakeAuthHandoffRepository repository = _FakeAuthHandoffRepository(
        errors: <Object>[const AppException.connection()],
        session: _session,
      );

      final AuthHandoffExchangeCubit cubit = AuthHandoffExchangeCubit(
        repository: repository,
      );

      await cubit.exchange('handoff-token');

      expect(cubit.state, isA<AuthHandoffExchangeFailure>());

      await cubit.retry();

      expect(cubit.state, const AuthHandoffExchangeSuccess(_session));

      expect(repository.exchangeCalls, 2);

      await cubit.close();
    });
  });
}

const AuthSession _session = AuthSession(
  accessToken: 'web-access-token',
  expiresIn: Duration(minutes: 15),
);

final class _FakeAuthHandoffRepository implements AuthHandoffRepository {
  _FakeAuthHandoffRepository({this.session, this.error, List<Object>? errors})
    : _errors = errors ?? <Object>[];

  final AuthSession? session;
  final Object? error;

  final List<Object> _errors;

  int exchangeCalls = 0;
  String? lastToken;

  @override
  Future<AuthHandoff> create() {
    throw UnimplementedError();
  }

  @override
  Future<AuthSession> exchange(String token) async {
    exchangeCalls += 1;
    lastToken = token;

    if (_errors.isNotEmpty) {
      throw _errors.removeAt(0);
    }

    final Object? exchangeError = error;

    if (exchangeError != null) {
      throw exchangeError;
    }

    return session ?? _session;
  }
}
