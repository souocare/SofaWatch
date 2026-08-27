import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/server/application/cubit/server_logs_state.dart';
import 'package:sofawatch/features/server/domain/models/server_logs.dart';
import 'package:sofawatch/features/server/domain/repositories/server_repository.dart';

final class ServerLogsCubit extends Cubit<ServerLogsState> {
  ServerLogsCubit({required this._repository, this.pageSize = 50})
    : super(const ServerLogsInitial());

  final ServerRepository _repository;
  final int pageSize;

  int _generation = 0;

  Future<void> load() async {
    final ServerLogsState currentState = state;

    if (currentState is ServerLogsLoading) {
      return;
    }

    final ServerLogLevel? level = switch (currentState) {
      ServerLogsSuccess(:final level) => level,
      ServerLogsFailure(:final level) => level,
      _ => null,
    };

    final int generation = ++_generation;

    emit(const ServerLogsLoading());

    try {
      final ServerLogsPage page = await _repository.getLogs(
        level: level,
        offset: 0,
        limit: pageSize,
      );

      if (isClosed || generation != _generation) {
        return;
      }

      emit(ServerLogsSuccess(page: page, level: level));
    } on AppException catch (error) {
      if (isClosed || generation != _generation) {
        return;
      }

      emit(ServerLogsFailure(error: error, level: level));
    } on Object catch (error) {
      if (isClosed || generation != _generation) {
        return;
      }

      emit(
        ServerLogsFailure(
          error: AppException.unknown(originalError: error),
          level: level,
        ),
      );
    }
  }

  Future<void> retry() {
    return load();
  }

  Future<void> setLevel(ServerLogLevel? level) async {
    final ServerLogsState currentState = state;

    if (currentState is ServerLogsSuccess && currentState.level == level) {
      return;
    }

    final int generation = ++_generation;

    emit(const ServerLogsLoading());

    try {
      final ServerLogsPage page = await _repository.getLogs(
        level: level,
        offset: 0,
        limit: pageSize,
      );

      if (isClosed || generation != _generation) {
        return;
      }

      emit(ServerLogsSuccess(page: page, level: level));
    } on AppException catch (error) {
      if (isClosed || generation != _generation) {
        return;
      }

      emit(ServerLogsFailure(error: error, level: level));
    } on Object catch (error) {
      if (isClosed || generation != _generation) {
        return;
      }

      emit(
        ServerLogsFailure(
          error: AppException.unknown(originalError: error),
          level: level,
        ),
      );
    }
  }

  Future<void> refresh() async {
    final ServerLogsState currentState = state;

    if (currentState is! ServerLogsSuccess || currentState.isRefreshing) {
      return;
    }

    final int generation = ++_generation;

    emit(currentState.copyWith(isRefreshing: true, clearRefreshError: true));

    try {
      final ServerLogsPage page = await _repository.getLogs(
        level: currentState.level,
        offset: 0,
        limit: pageSize,
      );

      if (isClosed || generation != _generation) {
        return;
      }

      final ServerLogsState latestState = state;

      if (latestState is! ServerLogsSuccess) {
        return;
      }

      emit(
        latestState.copyWith(
          page: page,
          isRefreshing: false,
          clearRefreshError: true,
          clearPaginationError: true,
        ),
      );
    } on AppException catch (error) {
      if (isClosed || generation != _generation) {
        return;
      }

      final ServerLogsState latestState = state;

      if (latestState is! ServerLogsSuccess) {
        return;
      }

      emit(latestState.copyWith(isRefreshing: false, refreshError: error));
    } on Object catch (error) {
      if (isClosed || generation != _generation) {
        return;
      }

      final ServerLogsState latestState = state;

      if (latestState is! ServerLogsSuccess) {
        return;
      }

      emit(
        latestState.copyWith(
          isRefreshing: false,
          refreshError: AppException.unknown(originalError: error),
        ),
      );
    }
  }

  Future<void> loadMore() async {
    final ServerLogsState currentState = state;

    if (currentState is! ServerLogsSuccess || !currentState.canLoadMore) {
      return;
    }

    final int generation = _generation;

    emit(
      currentState.copyWith(isLoadingMore: true, clearPaginationError: true),
    );

    try {
      final ServerLogsPage nextPage = await _repository.getLogs(
        level: currentState.level,
        offset: currentState.page.items.length,
        limit: pageSize,
      );

      if (isClosed || generation != _generation) {
        return;
      }

      final ServerLogsState latestState = state;

      if (latestState is! ServerLogsSuccess) {
        return;
      }

      final ServerLogsPage combinedPage = ServerLogsPage(
        items: <ServerLogEntry>[...currentState.page.items, ...nextPage.items],
        offset: 0,
        limit: pageSize,
        total: nextPage.total,
        hasNext: nextPage.hasNext,
      );

      emit(
        latestState.copyWith(
          page: combinedPage,
          isLoadingMore: false,
          clearPaginationError: true,
        ),
      );
    } on AppException catch (error) {
      if (isClosed || generation != _generation) {
        return;
      }

      final ServerLogsState latestState = state;

      if (latestState is! ServerLogsSuccess) {
        return;
      }

      emit(latestState.copyWith(isLoadingMore: false, paginationError: error));
    } on Object catch (error) {
      if (isClosed || generation != _generation) {
        return;
      }

      final ServerLogsState latestState = state;

      if (latestState is! ServerLogsSuccess) {
        return;
      }

      emit(
        latestState.copyWith(
          isLoadingMore: false,
          paginationError: AppException.unknown(originalError: error),
        ),
      );
    }
  }

  Future<void> retryPagination() {
    return loadMore();
  }

  @override
  Future<void> close() {
    _generation++;

    return super.close();
  }
}
