import 'package:sofawatch/features/explore/data/models/explore_media_item_dto.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending.dart';

class ExploreTrendingDto {
  const ExploreTrendingDto({required this.shows, required this.movies});

  factory ExploreTrendingDto.fromJson(Map<String, dynamic> json) {
    return ExploreTrendingDto(
      shows: _parseItems(json['shows'], 'shows'),
      movies: _parseItems(json['movies'], 'movies'),
    );
  }

  final List<ExploreMediaItemDto> shows;
  final List<ExploreMediaItemDto> movies;

  ExploreTrending toDomain() {
    return ExploreTrending(
      shows: shows.map((ExploreMediaItemDto item) => item.toDomain()).toList(),
      movies: movies
          .map((ExploreMediaItemDto item) => item.toDomain())
          .toList(),
    );
  }

  static List<ExploreMediaItemDto> _parseItems(Object? value, String key) {
    if (value is! List<dynamic>) {
      throw FormatException('Invalid Explore "$key" list.');
    }

    return List<ExploreMediaItemDto>.unmodifiable(
      value.map((Object? item) {
        if (item is! Map<String, dynamic>) {
          throw FormatException('Invalid Explore "$key" item.');
        }

        return ExploreMediaItemDto.fromJson(item);
      }),
    );
  }
}
