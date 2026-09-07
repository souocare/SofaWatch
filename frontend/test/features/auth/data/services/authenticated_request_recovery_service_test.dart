import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/data/services/authenticated_request_recovery_service.dart';
import 'package:sofawatch/features/auth/domain/models/auth_session.dart';
import 'package:sofawatch/features/auth/domain/repositories/auth_repository.dart';

void main() {
  group('AuthenticatedRequestRecoveryService', () {
    test('returns true without clearing authentication or emitting '
        'authenticationLost when restore succeeds', () async {
      final _FakeAuthRepository repository = _FakeAuthRepository(
        restoreResult: const AuthSession(
          accessToken: 'refreshed-access-token',
          expiresIn: Duration(minutes: 15),
        ),
      );
      final AuthenticatedRequestRecoveryService service =
          AuthenticatedRequestRecoveryService(repository: repository);

      var authenticationLostEvents = 0;
      final StreamSubscription<void> subscription = service.authenticationLost
          .listen((_) {
            authenticationLostEvents++;
          });

      final bool recovered = await service.recover();

      await Future<void>.delayed(Duration.zero);

      expect(recovered, isTrue);
      expect(repository.restoreCalls, 1);
      expect(repository.clearLocalAuthenticationCalls, 0);
      expect(authenticationLostEvents, 0);

      await subscription.cancel();
      await service.dispose();
    });

    test('emits authenticationLost authenticationLost '
        'when restore returns null', () async {
      final _FakeAuthRepository repository = _FakeAuthRepository();
      final AuthenticatedRequestRecoveryService service =
          AuthenticatedRequestRecoveryService(repository: repository);

      var authenticationLostEvents = 0;
      final StreamSubscription<void> subscription = service.authenticationLost
          .listen((_) {
            authenticationLostEvents++;
          });

      final bool recovered = await service.recover();

      await Future<void>.delayed(Duration.zero);

      expect(recovered, isFalse);
      expect(repository.restoreCalls, 1);
      expect(repository.clearLocalAuthenticationCalls, 0);
      expect(authenticationLostEvents, 1);

      await subscription.cancel();
      await service.dispose();
    });

    test('emits authenticationLost authenticationLost '
        'when refresh token is invalid', () async {
      final _FakeAuthRepository repository = _FakeAuthRepository(
        restoreError: const AppException(
          type: AppExceptionType.unauthorized,
          code: 'invalid_refresh_token',
          statusCode: 401,
          message: 'The refresh token is invalid or expired.',
        ),
      );
      final AuthenticatedRequestRecoveryService service =
          AuthenticatedRequestRecoveryService(repository: repository);

      var authenticationLostEvents = 0;
      final StreamSubscription<void> subscription = service.authenticationLost
          .listen((_) {
            authenticationLostEvents++;
          });

      final bool recovered = await service.recover();

      await Future<void>.delayed(Duration.zero);

      expect(recovered, isFalse);
      expect(repository.restoreCalls, 1);
      expect(repository.clearLocalAuthenticationCalls, 0);
      expect(authenticationLostEvents, 1);

      await subscription.cancel();
      await service.dispose();
    });

    test('emits authenticationLost authenticationLost '
        'when session is invalid', () async {
      final _FakeAuthRepository repository = _FakeAuthRepository(
        restoreError: const AppException(
          type: AppExceptionType.unauthorized,
          code: 'invalid_session',
          statusCode: 401,
          message: 'The session is invalid or expired.',
        ),
      );
      final AuthenticatedRequestRecoveryService service =
          AuthenticatedRequestRecoveryService(repository: repository);

      var authenticationLostEvents = 0;
      final StreamSubscription<void> subscription = service.authenticationLost
          .listen((_) {
            authenticationLostEvents++;
          });

      final bool recovered = await service.recover();

      await Future<void>.delayed(Duration.zero);

      expect(recovered, isFalse);
      expect(repository.restoreCalls, 1);
      expect(repository.clearLocalAuthenticationCalls, 0);
      expect(authenticationLostEvents, 1);

      await subscription.cancel();
      await service.dispose();
    });

    test(
      'emits authenticationLost synchronously when restore returns null',
      () async {
        final _FakeAuthRepository repository = _FakeAuthRepository();
        final AuthenticatedRequestRecoveryService service =
            AuthenticatedRequestRecoveryService(repository: repository);

        var authenticationLostEvents = 0;

        final StreamSubscription<void> subscription = service.authenticationLost
            .listen((_) {
              authenticationLostEvents++;
            });

        final Future<bool> recovery = service.recover();

        final bool recovered = await recovery;

        expect(recovered, isFalse);
        expect(repository.restoreCalls, 1);
        expect(repository.clearLocalAuthenticationCalls, 0);
        expect(authenticationLostEvents, 1);

        await subscription.cancel();
        await service.dispose();
      },
    );

    test(
      'delivers authenticationLost before a failed recovery completes',
      () async {
        final _FakeAuthRepository repository = _FakeAuthRepository();
        final AuthenticatedRequestRecoveryService service =
            AuthenticatedRequestRecoveryService(repository: repository);

        final List<String> events = <String>[];

        final StreamSubscription<void> subscription = service.authenticationLost
            .listen((_) {
              events.add('authentication-lost');
            });

        final bool recovered = await service.recover().then((bool result) {
          events.add('recovery-completed');

          return result;
        });

        expect(recovered, isFalse);
        expect(events, <String>['authentication-lost', 'recovery-completed']);

        await subscription.cancel();
        await service.dispose();
      },
    );

    test('rethrows transient restore errors without clearing authentication '
        'or emitting authenticationLost', () async {
      const AppException restoreError = AppException(
        type: AppExceptionType.connection,
        code: 'network_error',
        message: 'Unable to reach the server.',
      );

      final _FakeAuthRepository repository = _FakeAuthRepository(
        restoreError: restoreError,
      );
      final AuthenticatedRequestRecoveryService service =
          AuthenticatedRequestRecoveryService(repository: repository);

      var authenticationLostEvents = 0;
      final StreamSubscription<void> subscription = service.authenticationLost
          .listen((_) {
            authenticationLostEvents++;
          });

      await expectLater(service.recover(), throwsA(same(restoreError)));

      await Future<void>.delayed(Duration.zero);

      expect(repository.restoreCalls, 1);
      expect(repository.clearLocalAuthenticationCalls, 0);
      expect(authenticationLostEvents, 0);

      await subscription.cancel();
      await service.dispose();
    });

    test(
      'shares one restore operation across concurrent recovery calls',
      () async {
        final Completer<AuthSession?> restoreCompleter =
            Completer<AuthSession?>();

        final _FakeAuthRepository repository = _FakeAuthRepository(
          restoreFuture: restoreCompleter.future,
        );
        final AuthenticatedRequestRecoveryService service =
            AuthenticatedRequestRecoveryService(repository: repository);

        final Future<bool> firstRecovery = service.recover();
        final Future<bool> secondRecovery = service.recover();
        final Future<bool> thirdRecovery = service.recover();

        expect(repository.restoreCalls, 1);

        restoreCompleter.complete(
          const AuthSession(
            accessToken: 'refreshed-access-token',
            expiresIn: Duration(minutes: 15),
          ),
        );

        final List<bool> results = await Future.wait(<Future<bool>>[
          firstRecovery,
          secondRecovery,
          thirdRecovery,
        ]);

        expect(results, <bool>[true, true, true]);
        expect(repository.restoreCalls, 1);
        expect(repository.clearLocalAuthenticationCalls, 0);

        await service.dispose();
      },
    );
  });
}

final class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.restoreResult,
    this.restoreError,
    this.restoreFuture,
  });

  final AuthSession? restoreResult;
  final AppException? restoreError;
  final Future<AuthSession?>? restoreFuture;

  int restoreCalls = 0;
  int clearLocalAuthenticationCalls = 0;

  @override
  Future<AuthSession?> restore() async {
    restoreCalls++;

    final Future<AuthSession?>? future = restoreFuture;

    if (future != null) {
      return future;
    }

    final AppException? error = restoreError;

    if (error != null) {
      throw error;
    }

    return restoreResult;
  }

  @override
  Future<void> clearLocalAuthentication() async {
    clearLocalAuthenticationCalls++;
  }

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() {
    throw UnimplementedError();
  }

  @override
  Future<void> logoutEverywhere() {
    throw UnimplementedError();
  }
}
