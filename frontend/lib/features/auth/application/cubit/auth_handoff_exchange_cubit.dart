import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_handoff_exchange_state.dart';
import 'package:sofawatch/features/auth/domain/models/auth_session.dart';
import 'package:sofawatch/features/auth/domain/repositories/auth_handoff_repository.dart';

final class AuthHandoffExchangeCubit extends Cubit<AuthHandoffExchangeState> {
  AuthHandoffExchangeCubit({required this._repository})
    : super(const AuthHandoffExchangeInitial());

  final AuthHandoffRepository _repository;

  String? _token;

  Future<void> exchange(String? token) async {
    if (state is AuthHandoffExchangeLoading ||
        state is AuthHandoffExchangeSuccess) {
      return;
    }

    final String normalizedToken = token?.trim() ?? '';

    _token = normalizedToken;

    if (normalizedToken.isEmpty) {
      emit(const AuthHandoffExchangeInvalid());
      return;
    }

    emit(const AuthHandoffExchangeLoading());

    try {
      final AuthSession session = await _repository.exchange(normalizedToken);

      if (isClosed) {
        return;
      }

      emit(AuthHandoffExchangeSuccess(session));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      if (_representsInvalidHandoff(error)) {
        emit(const AuthHandoffExchangeInvalid());
        return;
      }

      emit(AuthHandoffExchangeFailure(error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        AuthHandoffExchangeFailure(AppException.unknown(originalError: error)),
      );
    }
  }

  Future<void> retry() {
    return exchange(_token);
  }

  static bool _representsInvalidHandoff(AppException error) {
    return error.type == AppExceptionType.unauthorized &&
        error.code == 'invalid_auth_handoff';
  }
}
