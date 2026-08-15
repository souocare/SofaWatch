import 'package:equatable/equatable.dart';

final class LibraryShowProgress extends Equatable {
  const LibraryShowProgress({
    required this.watchedEpisodes,
    required this.airedEpisodes,
    required this.percentage,
    required this.caughtUp,
  });

  final int watchedEpisodes;
  final int airedEpisodes;
  final double percentage;
  final bool caughtUp;

  @override
  List<Object?> get props => <Object?>[
    watchedEpisodes,
    airedEpisodes,
    percentage,
    caughtUp,
  ];
}
