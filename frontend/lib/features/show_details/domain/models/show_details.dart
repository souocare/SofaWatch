import 'package:equatable/equatable.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_genre.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_network.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_season.dart';

final class ShowDetails extends Equatable {
  const ShowDetails({
    required this.tmdbId,
    required this.title,
    required this.originalTitle,
    required this.originalLanguage,
    required this.numberOfSeasons,
    required this.numberOfEpisodes,
    required this.inProduction,
    required this.status,
    required this.showType,
    required this.popularity,
    required this.voteAverage,
    required this.voteCount,
    required this.genres,
    required this.seasons,
    required this.networks,
    required this.episodeRunTimes,
    this.overview,
    this.tagline,
    this.firstAirDate,
    this.lastAirDate,
    this.posterUrl,
    this.backdropUrl,
    this.homepageUrl,
  });

  final int tmdbId;

  final String title;
  final String originalTitle;

  final String? overview;
  final String? tagline;

  final DateTime? firstAirDate;
  final DateTime? lastAirDate;

  final String? posterUrl;
  final String? backdropUrl;

  final String? homepageUrl;

  final List<ShowDetailsGenre> genres;
  final List<ShowDetailsSeason> seasons;
  final List<ShowDetailsNetwork> networks;

  final String originalLanguage;

  final List<int> episodeRunTimes;

  final int numberOfSeasons;
  final int numberOfEpisodes;

  final bool inProduction;

  final String status;
  final String showType;

  final double popularity;

  final double voteAverage;
  final int voteCount;

  int? get releaseYear => firstAirDate?.year;

  int? get endYear => lastAirDate?.year;

  int? get primaryEpisodeRunTime {
    if (episodeRunTimes.isEmpty) {
      return null;
    }

    return episodeRunTimes.first;
  }

  bool get hasEnded {
    return !inProduction && lastAirDate != null;
  }

  @override
  List<Object?> get props => <Object?>[
    tmdbId,
    title,
    originalTitle,
    overview,
    tagline,
    firstAirDate,
    lastAirDate,
    posterUrl,
    backdropUrl,
    homepageUrl,
    genres,
    seasons,
    networks,
    originalLanguage,
    episodeRunTimes,
    numberOfSeasons,
    numberOfEpisodes,
    inProduction,
    status,
    showType,
    popularity,
    voteAverage,
    voteCount,
  ];
}
