import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/core/state/remote_status.dart';

class RemoteState<T> extends Equatable {
  const RemoteState({
    this.status = RemoteStatus.initial,
    this.data,
    this.error,
  });

  const RemoteState.initial()
    : status = RemoteStatus.initial,
      data = null,
      error = null;

  const RemoteState.loading({this.data})
    : status = RemoteStatus.loading,
      error = null;

  const RemoteState.success(T this.data)
    : status = RemoteStatus.success,
      error = null;

  const RemoteState.failure(AppException this.error, {this.data})
    : status = RemoteStatus.failure;

  final RemoteStatus status;
  final T? data;
  final AppException? error;

  bool get isInitial {
    return status == RemoteStatus.initial;
  }

  bool get isLoading {
    return status == RemoteStatus.loading;
  }

  bool get isSuccess {
    return status == RemoteStatus.success;
  }

  bool get isFailure {
    return status == RemoteStatus.failure;
  }

  bool get hasData {
    return data != null;
  }

  bool get hasError {
    return error != null;
  }

  bool get isRefreshing {
    return isLoading && hasData;
  }

  RemoteState<T> copyWith({
    RemoteStatus? status,
    T? data,
    bool clearData = false,
    AppException? error,
    bool clearError = false,
  }) {
    return RemoteState<T>(
      status: status ?? this.status,
      data: clearData ? null : data ?? this.data,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, data, error];
}
