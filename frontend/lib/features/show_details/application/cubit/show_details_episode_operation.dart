import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';

enum ShowDetailsEpisodeOperationStatus { idle, updating, failure }

enum ShowDetailsEpisodeOperationIntent { setWatchedState, rewatch }

final class ShowDetailsEpisodeOperation extends Equatable {
  const ShowDetailsEpisodeOperation._({
    required this.status,
    this.error,
    this.targetWatched,
    this.intent,
  });

  const ShowDetailsEpisodeOperation.idle()
    : this._(status: ShowDetailsEpisodeOperationStatus.idle);

  const ShowDetailsEpisodeOperation.updating({
    required bool targetWatched,
    ShowDetailsEpisodeOperationIntent intent =
        ShowDetailsEpisodeOperationIntent.setWatchedState,
  }) : this._(
         status: ShowDetailsEpisodeOperationStatus.updating,
         targetWatched: targetWatched,
         intent: intent,
       );

  const ShowDetailsEpisodeOperation.failure(
    AppException error, {
    required bool targetWatched,
    ShowDetailsEpisodeOperationIntent intent =
        ShowDetailsEpisodeOperationIntent.setWatchedState,
  }) : this._(
         status: ShowDetailsEpisodeOperationStatus.failure,
         error: error,
         targetWatched: targetWatched,
         intent: intent,
       );

  final ShowDetailsEpisodeOperationStatus status;
  final AppException? error;

  final bool? targetWatched;

  final ShowDetailsEpisodeOperationIntent? intent;

  bool get isUpdating {
    return status == ShowDetailsEpisodeOperationStatus.updating;
  }

  bool get hasFailed {
    return status == ShowDetailsEpisodeOperationStatus.failure;
  }

  bool get isRewatch {
    return intent == ShowDetailsEpisodeOperationIntent.rewatch;
  }

  @override
  List<Object?> get props => <Object?>[status, error, targetWatched, intent];
}
