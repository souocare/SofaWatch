import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/history/domain/models/history_movie_item.dart';

final class MovieHistoryState extends Equatable {
  const MovieHistoryState({
    this.items = const <HistoryMovieItem>[],
    this.isLoading = false,
    this.error,
    this.mutationError,
    this.mutatingMovieIds = const <String>{},
    this.mutatingEventIds = const <String>{},
  });

  final List<HistoryMovieItem> items;

  /// Whether the Movie History preview is being loaded.
  ///
  /// Existing items may remain visible during a notifier-driven refresh.
  final bool isLoading;

  /// Failure while loading the Movie History preview.
  final AppException? error;

  /// Failure produced by a Watch/Rewatch/Delete mutation.
  ///
  /// Mutation failures must not replace already loaded History content.
  final AppException? mutationError;

  /// Movie IDs currently recording a new viewing.
  ///
  /// This covers both:
  /// - first viewing from Watchlist;
  /// - Rewatch from an existing History event.
  final Set<String> mutatingMovieIds;

  /// Historical event IDs currently being deleted.
  final Set<String> mutatingEventIds;

  bool get hasError => error != null;

  bool get isEmpty => items.isEmpty;

  bool isMovieMutating(String movieId) {
    return mutatingMovieIds.contains(movieId);
  }

  bool isEventMutating(String eventId) {
    return mutatingEventIds.contains(eventId);
  }

  MovieHistoryState copyWith({
    List<HistoryMovieItem>? items,
    bool? isLoading,
    AppException? error,
    bool clearError = false,
    AppException? mutationError,
    bool clearMutationError = false,
    Set<String>? mutatingMovieIds,
    Set<String>? mutatingEventIds,
  }) {
    return MovieHistoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      mutationError: clearMutationError
          ? null
          : mutationError ?? this.mutationError,
      mutatingMovieIds: mutatingMovieIds ?? this.mutatingMovieIds,
      mutatingEventIds: mutatingEventIds ?? this.mutatingEventIds,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    items,
    isLoading,
    error,
    mutationError,
    mutatingMovieIds,
    mutatingEventIds,
  ];
}
