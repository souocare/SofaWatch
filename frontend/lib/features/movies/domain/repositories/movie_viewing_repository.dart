abstract interface class MovieViewingRepository {
  /// Records a new viewing of [movieId].
  ///
  /// Recording another viewing for an already watched Movie represents
  /// a Rewatch and therefore creates a new historical watch event.
  Future<void> recordWatch(String movieId);

  /// Deletes one specific historical viewing.
  ///
  /// If this is the Movie's last remaining watch event, the backend is
  /// responsible for returning the Movie to the Watchlist.
  Future<void> deleteWatchEvent({
    required String movieId,
    required String eventId,
  });
}
