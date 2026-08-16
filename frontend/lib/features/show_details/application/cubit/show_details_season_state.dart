import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_episode_operation.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_episode.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_episode_progress.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_season_progress.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_season_operation.dart';

final class ShowDetailsSeasonState extends Equatable {
  const ShowDetailsSeasonState({
    this.isExpanded = false,
    this.isLoading = false,
    this.hasLoadedEpisodes = false,
    this.episodes = const <ShowDetailsEpisode>[],
    this.episodeProgressById = const <String, ShowDetailsEpisodeProgress>{},
    this.episodeOperationsById = const <String, ShowDetailsEpisodeOperation>{},
    this.progress,
    this.error,
    this.operation = const ShowDetailsSeasonOperation.idle(),
  });

  final bool isExpanded;
  final bool isLoading;

  final bool hasLoadedEpisodes;

  final List<ShowDetailsEpisode> episodes;

  final Map<String, ShowDetailsEpisodeProgress> episodeProgressById;

  final Map<String, ShowDetailsEpisodeOperation> episodeOperationsById;

  final ShowDetailsSeasonProgress? progress;

  final AppException? error;

  final ShowDetailsSeasonOperation operation;

  bool get isLoaded {
    return hasLoadedEpisodes && !isLoading && error == null;
  }

  bool get hasError => error != null;

  ShowDetailsEpisodeOperation operationForEpisode(String episodeId) {
    return episodeOperationsById[episodeId] ??
        const ShowDetailsEpisodeOperation.idle();
  }

  ShowDetailsSeasonState copyWith({
    bool? isExpanded,
    bool? isLoading,
    bool? hasLoadedEpisodes,
    List<ShowDetailsEpisode>? episodes,
    Map<String, ShowDetailsEpisodeProgress>? episodeProgressById,
    Map<String, ShowDetailsEpisodeOperation>? episodeOperationsById,
    ShowDetailsSeasonProgress? progress,
    AppException? error,
    bool clearError = false,
    ShowDetailsSeasonOperation? operation,
  }) {
    return ShowDetailsSeasonState(
      isExpanded: isExpanded ?? this.isExpanded,
      isLoading: isLoading ?? this.isLoading,
      hasLoadedEpisodes: hasLoadedEpisodes ?? this.hasLoadedEpisodes,
      episodes: episodes ?? this.episodes,
      episodeProgressById: episodeProgressById ?? this.episodeProgressById,
      episodeOperationsById:
          episodeOperationsById ?? this.episodeOperationsById,
      progress: progress ?? this.progress,
      error: clearError ? null : error ?? this.error,
      operation: operation ?? this.operation,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    isExpanded,
    isLoading,
    hasLoadedEpisodes,
    episodes,
    episodeProgressById,
    episodeOperationsById,
    progress,
    error,
    operation,
  ];
}
