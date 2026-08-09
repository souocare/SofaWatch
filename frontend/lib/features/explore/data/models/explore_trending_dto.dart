import 'package:sofawatch/features/explore/data/models/explore_media_item_dto.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending.dart';

class ExploreTrendingDto {
  const ExploreTrendingDto({required this.items});

  factory ExploreTrendingDto.fromJson(Map<String, dynamic> json) {
    final Object? itemsJson = json['items'];

    if (itemsJson is! List<dynamic>) {
      throw const FormatException('Invalid Explore trending items.');
    }

    return ExploreTrendingDto(
      items: List<ExploreMediaItemDto>.unmodifiable(
        itemsJson.map((Object? item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('Invalid Explore trending item.');
          }

          return ExploreMediaItemDto.fromJson(item);
        }),
      ),
    );
  }

  final List<ExploreMediaItemDto> items;

  ExploreTrending toDomain() {
    return ExploreTrending(
      items: items.map((ExploreMediaItemDto item) => item.toDomain()).toList(),
    );
  }
}
