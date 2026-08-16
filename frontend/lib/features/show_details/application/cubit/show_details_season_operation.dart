import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';

enum ShowDetailsSeasonOperationStatus { idle, updating, failure }

final class ShowDetailsSeasonOperation extends Equatable {
  const ShowDetailsSeasonOperation._({required this.status, this.error});

  const ShowDetailsSeasonOperation.idle()
    : this._(status: ShowDetailsSeasonOperationStatus.idle);

  const ShowDetailsSeasonOperation.updating()
    : this._(status: ShowDetailsSeasonOperationStatus.updating);

  const ShowDetailsSeasonOperation.failure(AppException error)
    : this._(status: ShowDetailsSeasonOperationStatus.failure, error: error);

  final ShowDetailsSeasonOperationStatus status;
  final AppException? error;

  bool get isUpdating {
    return status == ShowDetailsSeasonOperationStatus.updating;
  }

  bool get hasFailed {
    return status == ShowDetailsSeasonOperationStatus.failure;
  }

  @override
  List<Object?> get props => <Object?>[status, error];
}
