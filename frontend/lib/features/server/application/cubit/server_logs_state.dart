import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/server/domain/models/server_logs.dart';

sealed class ServerLogsState extends Equatable {
  const ServerLogsState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class ServerLogsInitial extends ServerLogsState {
  const ServerLogsInitial();
}

final class ServerLogsLoading extends ServerLogsState {
  const ServerLogsLoading();
}

final class ServerLogsSuccess extends ServerLogsState {
  const ServerLogsSuccess({
    required this.page,
    this.level,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.refreshError,
    this.paginationError,
  });

  final ServerLogsPage page;
  final ServerLogLevel? level;

  final bool isRefreshing;
  final bool isLoadingMore;

  final AppException? refreshError;
  final AppException? paginationError;

  bool get canLoadMore {
    return page.hasNext && !isLoadingMore && !isRefreshing;
  }

  ServerLogsSuccess copyWith({
    ServerLogsPage? page,
    ServerLogLevel? level,
    bool clearLevel = false,
    bool? isRefreshing,
    bool? isLoadingMore,
    AppException? refreshError,
    bool clearRefreshError = false,
    AppException? paginationError,
    bool clearPaginationError = false,
  }) {
    return ServerLogsSuccess(
      page: page ?? this.page,
      level: clearLevel ? null : level ?? this.level,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      refreshError: clearRefreshError
          ? null
          : refreshError ?? this.refreshError,
      paginationError: clearPaginationError
          ? null
          : paginationError ?? this.paginationError,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    page,
    level,
    isRefreshing,
    isLoadingMore,
    refreshError,
    paginationError,
  ];
}

final class ServerLogsFailure extends ServerLogsState {
  const ServerLogsFailure({required this.error, this.level});

  final AppException error;
  final ServerLogLevel? level;

  @override
  List<Object?> get props => <Object?>[error, level];
}
