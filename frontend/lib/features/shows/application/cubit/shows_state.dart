import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_show.dart';

final class ShowsState extends Equatable {
  const ShowsState({
    this.libraryShows = const <LibraryShow>[],
    this.watchNext = const <WatchNextShow>[],
    this.isLoading = false,
    this.watchNextError,
    this.error,
  });

  final List<LibraryShow> libraryShows;
  final List<WatchNextShow> watchNext;

  final bool isLoading;

  /// Failure of the supplementary Watch Next block.
  ///
  /// This must not make the entire Shows screen unusable.
  final AppException? watchNextError;

  /// Fatal failure while loading the core Shows/Library data.
  final AppException? error;

  bool get hasFatalError => error != null;

  bool get isLibraryEmpty => libraryShows.isEmpty;

  bool get isWatchNextEmpty => watchNext.isEmpty;

  ShowsState copyWith({
    List<LibraryShow>? libraryShows,
    List<WatchNextShow>? watchNext,
    bool? isLoading,
    AppException? watchNextError,
    bool clearWatchNextError = false,
    AppException? error,
    bool clearError = false,
  }) {
    return ShowsState(
      libraryShows: libraryShows ?? this.libraryShows,
      watchNext: watchNext ?? this.watchNext,
      isLoading: isLoading ?? this.isLoading,
      watchNextError: clearWatchNextError
          ? null
          : watchNextError ?? this.watchNextError,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    libraryShows,
    watchNext,
    isLoading,
    watchNextError,
    error,
  ];
}
