import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/episode_details/application/cubit/episode_details_operation.dart';
import 'package:sofawatch/features/episode_details/domain/models/episode_details.dart';

sealed class EpisodeDetailsState extends Equatable {
  const EpisodeDetailsState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class EpisodeDetailsInitial extends EpisodeDetailsState {
  const EpisodeDetailsInitial();
}

final class EpisodeDetailsLoading extends EpisodeDetailsState {
  const EpisodeDetailsLoading();
}

final class EpisodeDetailsSuccess extends EpisodeDetailsState {
  const EpisodeDetailsSuccess(
    this.details, {
    this.operation = const EpisodeDetailsOperation.idle(),
  });

  final EpisodeDetails details;
  final EpisodeDetailsOperation operation;

  EpisodeDetailsSuccess copyWith({
    EpisodeDetails? details,
    EpisodeDetailsOperation? operation,
  }) {
    return EpisodeDetailsSuccess(
      details ?? this.details,
      operation: operation ?? this.operation,
    );
  }

  @override
  List<Object?> get props => <Object?>[details, operation];
}

final class EpisodeDetailsFailure extends EpisodeDetailsState {
  const EpisodeDetailsFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => <Object?>[error];
}
