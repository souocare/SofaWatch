import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';

enum ShowDetailsShowOperationStatus { idle, updating, success, failure }

final class ShowDetailsShowOperation extends Equatable {
  const ShowDetailsShowOperation._({required this.status, this.error});

  const ShowDetailsShowOperation.idle()
    : this._(status: ShowDetailsShowOperationStatus.idle);

  const ShowDetailsShowOperation.updating()
    : this._(status: ShowDetailsShowOperationStatus.updating);

  const ShowDetailsShowOperation.success()
    : this._(status: ShowDetailsShowOperationStatus.success);

  const ShowDetailsShowOperation.failure(AppException error)
    : this._(status: ShowDetailsShowOperationStatus.failure, error: error);

  final ShowDetailsShowOperationStatus status;
  final AppException? error;

  bool get isUpdating {
    return status == ShowDetailsShowOperationStatus.updating;
  }

  bool get isSuccess {
    return status == ShowDetailsShowOperationStatus.success;
  }

  bool get hasFailed {
    return status == ShowDetailsShowOperationStatus.failure;
  }

  @override
  List<Object?> get props => <Object?>[status, error];
}
