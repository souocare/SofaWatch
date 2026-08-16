import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';

enum EpisodeDetailsOperationStatus { idle, updating, failure }

enum EpisodeDetailsOperationIntent { markWatched, markUnwatched, rewatch }

final class EpisodeDetailsOperation extends Equatable {
  const EpisodeDetailsOperation._({
    required this.status,
    this.intent,
    this.error,
  });

  const EpisodeDetailsOperation.idle()
    : this._(status: EpisodeDetailsOperationStatus.idle);

  const EpisodeDetailsOperation.updating({
    required EpisodeDetailsOperationIntent intent,
  }) : this._(status: EpisodeDetailsOperationStatus.updating, intent: intent);

  const EpisodeDetailsOperation.failure(
    AppException error, {
    required EpisodeDetailsOperationIntent intent,
  }) : this._(
         status: EpisodeDetailsOperationStatus.failure,
         intent: intent,
         error: error,
       );

  final EpisodeDetailsOperationStatus status;
  final EpisodeDetailsOperationIntent? intent;
  final AppException? error;

  bool get isUpdating {
    return status == EpisodeDetailsOperationStatus.updating;
  }

  bool get hasFailed {
    return status == EpisodeDetailsOperationStatus.failure;
  }

  @override
  List<Object?> get props => <Object?>[status, intent, error];
}
