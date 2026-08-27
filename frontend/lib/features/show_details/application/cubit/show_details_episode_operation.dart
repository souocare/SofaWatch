import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';

enum ShowDetailsEpisodeOperationStatus { idle, updating, failure }

enum ShowDetailsEpisodeOperationIntent {
  setWatchedState,
  catchUpWithPrevious,
  rewatch,
  removeLatestViewing,
  removeAllViewings,
}

final class ShowDetailsEpisodeOperation extends Equatable {
  const ShowDetailsEpisodeOperation._({
    required this.status,
    this.error,
    this.targetWatched,
    this.intent,
    this.eventId,
  });

  const ShowDetailsEpisodeOperation.idle()
    : this._(status: ShowDetailsEpisodeOperationStatus.idle);

  const ShowDetailsEpisodeOperation.updating({
    bool? targetWatched,
    required ShowDetailsEpisodeOperationIntent intent,
    String? eventId,
  }) : this._(
         status: ShowDetailsEpisodeOperationStatus.updating,
         targetWatched: targetWatched,
         intent: intent,
         eventId: eventId,
       );

  const ShowDetailsEpisodeOperation.failure(
    AppException error, {
    bool? targetWatched,
    required ShowDetailsEpisodeOperationIntent intent,
    String? eventId,
  }) : this._(
         status: ShowDetailsEpisodeOperationStatus.failure,
         error: error,
         targetWatched: targetWatched,
         intent: intent,
         eventId: eventId,
       );

  final ShowDetailsEpisodeOperationStatus status;
  final AppException? error;

  final bool? targetWatched;

  final ShowDetailsEpisodeOperationIntent? intent;

  /// Historical viewing targeted by an operation when applicable.
  final String? eventId;

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
  List<Object?> get props => <Object?>[
    status,
    error,
    targetWatched,
    intent,
    eventId,
  ];
}
