import 'dart:async';

import 'package:sofawatch/core/api/authenticated_request_recovery.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/domain/repositories/auth_repository.dart';

final class AuthenticatedRequestRecoveryService
    implements AuthenticatedRequestRecovery {
  AuthenticatedRequestRecoveryService({required this.repository});

  final AuthRepository repository;

  final StreamController<void> _authenticationLostController =
      StreamController<void>.broadcast(sync: true);

  Future<bool>? _recoveryInProgress;

  Stream<void> get authenticationLost => _authenticationLostController.stream;

  @override
  Future<bool> recover() {
    final Future<bool>? recoveryInProgress = _recoveryInProgress;

    if (recoveryInProgress != null) {
      return recoveryInProgress;
    }

    final Future<bool> recovery = _recover();

    _recoveryInProgress = recovery;

    return recovery.whenComplete(() {
      if (identical(_recoveryInProgress, recovery)) {
        _recoveryInProgress = null;
      }
    });
  }

  Future<bool> _recover() async {
    try {
      final session = await repository.restore();

      if (session == null) {
        _notifyAuthenticationLost();

        return false;
      }

      return true;
    } on AppException catch (error) {
      if (_isAuthenticationFailure(error)) {
        _notifyAuthenticationLost();

        return false;
      }

      rethrow;
    }
  }

  bool _isAuthenticationFailure(AppException error) {
    if (error.type != AppExceptionType.unauthorized) {
      return false;
    }

    return switch (error.code) {
      'invalid_refresh_token' ||
      'invalid_session' ||
      'session_required' => true,
      _ => false,
    };
  }

  Future<void> dispose() async {
    await _authenticationLostController.close();
  }

  void _notifyAuthenticationLost() {
    _authenticationLostController.add(null);
  }
}
