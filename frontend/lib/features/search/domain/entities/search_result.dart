import 'package:equatable/equatable.dart';
import 'package:sofawatch/features/search/domain/entities/search_media_type.dart';

class SearchResult extends Equatable {
  const SearchResult({
    required this.mediaType,
    required this.tmdbId,
    required this.title,
    required this.originalTitle,
    required this.originalLanguage,
    required this.genreIds,
    required this.popularity,
    required this.voteAverage,
    required this.voteCount,
    this.overview,
    this.releaseDate,
    this.posterUrl,
    this.backdropUrl,
    this.inLibrary = false,
  });

  final SearchMediaType mediaType;
  final int tmdbId;

  final String title;
  final String originalTitle;
  final String? overview;

  /// First-air date for a show or release date for a movie.
  final DateTime? releaseDate;

  final Uri? posterUrl;
  final Uri? backdropUrl;

  final String originalLanguage;
  final List<int> genreIds;

  final double popularity;
  final double voteAverage;
  final int voteCount;
  final bool inLibrary;

  bool get isShow {
    return mediaType == SearchMediaType.show;
  }

  bool get isMovie {
    return mediaType == SearchMediaType.movie;
  }

  int? get releaseYear {
    return releaseDate?.year;
  }

  bool get hasOverview {
    return overview?.trim().isNotEmpty == true;
  }

  bool get hasPoster {
    return posterUrl != null;
  }

  bool get hasBackdrop {
    return backdropUrl != null;
  }

  @override
  List<Object?> get props => <Object?>[
    mediaType,
    tmdbId,
    title,
    originalTitle,
    overview,
    releaseDate,
    posterUrl,
    backdropUrl,
    originalLanguage,
    genreIds,
    popularity,
    voteAverage,
    voteCount,
    inLibrary,
  ];
}
