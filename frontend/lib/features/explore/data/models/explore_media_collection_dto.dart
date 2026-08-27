import 'package:sofawatch/features/explore/data/models/explore_media_item_dto.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_collection.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_item.dart';

class ExploreMediaCollectionDto {
  const ExploreMediaCollectionDto({required this.items});
  factory ExploreMediaCollectionDto.fromJson(Map<String, dynamic> json) {
    final dynamic rawItems = json['items'];

    if (rawItems is! List) {
      throw const FormatException('Invalid Explore media items.');
    }

    final List<ExploreMediaItemDto> items = rawItems
        .map<ExploreMediaItemDto>((dynamic item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('Invalid Explore media item.');
          }

          return ExploreMediaItemDto.fromJson(item);
        })
        .toList(growable: false);

    return ExploreMediaCollectionDto(items: items);
  }

  final List<ExploreMediaItemDto> items;

  ExploreMediaCollection toDomain() {
    return ExploreMediaCollection(
      items: List<ExploreMediaItem>.unmodifiable(
        items.map((ExploreMediaItemDto item) => item.toDomain()),
      ),
    );
  }
}
