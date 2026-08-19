import 'package:equatable/equatable.dart';

final class LibraryPreview extends Equatable {
  const LibraryPreview({required this.shows, required this.movies});

  final List<LibraryPreviewShow> shows;
  final List<LibraryPreviewMovie> movies;

  @override
  List<Object?> get props => <Object?>[shows, movies];
}

final class LibraryPreviewShow extends Equatable {
  const LibraryPreviewShow({
    required this.id,
    required this.tmdbId,
    required this.title,
    required this.posterUrl,
  });

  final String id;
  final int tmdbId;
  final String title;
  final String? posterUrl;

  @override
  List<Object?> get props => <Object?>[id, tmdbId, title, posterUrl];
}

final class LibraryPreviewMovie extends Equatable {
  const LibraryPreviewMovie({
    required this.id,
    required this.tmdbId,
    required this.title,
    required this.posterUrl,
  });

  final String id;
  final int tmdbId;
  final String title;
  final String? posterUrl;

  @override
  List<Object?> get props => <Object?>[id, tmdbId, title, posterUrl];
}
