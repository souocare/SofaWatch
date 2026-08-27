import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/server/application/cubit/server_health_state.dart';
import 'package:sofawatch/features/server/domain/models/server_health.dart';
import 'package:sofawatch/features/server/domain/repositories/server_repository.dart';

final class ServerHealthCubit extends Cubit<ServerHealthState> {
  ServerHealthCubit({required this._repository})
    : super(const ServerHealthInitial());

  final ServerRepository _repository;

  Future<void> load() async {
    if (state is ServerHealthLoading) {
      return;
    }

    emit(const ServerHealthLoading());

    try {
      final ServerHealth health = await _repository.getHealth();

      if (isClosed) {
        return;
      }

      emit(ServerHealthSuccess(health));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(ServerHealthFailure(error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(ServerHealthFailure(AppException.unknown(originalError: error)));
    }
  }

  Future<void> retry() {
    return load();
  }
}
