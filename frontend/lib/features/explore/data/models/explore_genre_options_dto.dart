import 'package:sofawatch/features/explore/data/models/explore_genre_dto.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_genre.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_genre_options.dart';

final class ExploreGenreOptionsDto {
  const ExploreGenreOptionsDto({required this.shows, required this.movies});

  factory ExploreGenreOptionsDto.fromJson(Map<String, dynamic> json) {
    return ExploreGenreOptionsDto(
      shows: _parseGenres(json['shows'], fieldName: 'shows'),
      movies: _parseGenres(json['movies'], fieldName: 'movies'),
    );
  }

  final List<ExploreGenreDto> shows;
  final List<ExploreGenreDto> movies;

  ExploreGenreOptions toDomain() {
    return ExploreGenreOptions(
      shows: List<ExploreGenre>.unmodifiable(
        shows.map((ExploreGenreDto genre) => genre.toDomain()),
      ),
      movies: List<ExploreGenre>.unmodifiable(
        movies.map((ExploreGenreDto genre) => genre.toDomain()),
      ),
    );
  }

  static List<ExploreGenreDto> _parseGenres(
    Object? value, {
    required String fieldName,
  }) {
    if (value is! List<dynamic>) {
      throw FormatException('Invalid Explore "$fieldName" genres.');
    }

    return List<ExploreGenreDto>.unmodifiable(
      value.map((dynamic item) {
        if (item is! Map<String, dynamic>) {
          throw FormatException('Invalid Explore "$fieldName" genre.');
        }

        return ExploreGenreDto.fromJson(item);
      }),
    );
  }
}
