import 'package:equatable/equatable.dart';

final class EpisodeDetailsProgress extends Equatable {
  const EpisodeDetailsProgress({
    required this.isWatched,
    required this.watchCount,
    this.watchedAt,
    this.lastWatchedAt,
  });

  final bool isWatched;

  /// Current watched-state timestamp.
  ///
  /// This is null when the Episode is currently marked as unwatched.
  final DateTime? watchedAt;

  /// Number of historical viewing events recorded for this Episode.
  final int watchCount;

  /// Most recent historical viewing, even when the Episode is currently
  /// marked as unwatched.
  final DateTime? lastWatchedAt;

  bool get hasWatchHistory => watchCount > 0;

  bool get isRewatch => watchCount > 1;

  @override
  List<Object?> get props => <Object?>[
    isWatched,
    watchedAt,
    watchCount,
    lastWatchedAt,
  ];
}
