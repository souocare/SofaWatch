import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_episode.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_season_progress.dart';

final class ShowDetailsSeasonState extends Equatable {
  const ShowDetailsSeasonState({
    this.isExpanded = false,
    this.isLoading = false,
    this.episodes = const <ShowDetailsEpisode>[],
    this.progress,
    this.error,
  });

  final bool isExpanded;
  final bool isLoading;

  final List<ShowDetailsEpisode> episodes;

  final ShowDetailsSeasonProgress? progress;

  final AppException? error;

  bool get isLoaded {
    return !isLoading && error == null && progress != null;
  }

  bool get hasError => error != null;

  ShowDetailsSeasonState copyWith({
    bool? isExpanded,
    bool? isLoading,
    List<ShowDetailsEpisode>? episodes,
    ShowDetailsSeasonProgress? progress,
    AppException? error,
    bool clearError = false,
  }) {
    return ShowDetailsSeasonState(
      isExpanded: isExpanded ?? this.isExpanded,
      isLoading: isLoading ?? this.isLoading,
      episodes: episodes ?? this.episodes,
      progress: progress ?? this.progress,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    isExpanded,
    isLoading,
    episodes,
    progress,
    error,
  ];
}
