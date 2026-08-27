import 'package:sofawatch/features/shows/data/models/watch_history_item_dto.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_page.dart';

final class WatchHistoryPageDto {
  const WatchHistoryPageDto({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });
  factory WatchHistoryPageDto.fromJson(Map<String, dynamic> json) {
    final Object? rawItems = json['items'];

    if (rawItems is! List<dynamic>) {
      throw const FormatException('Invalid Watch History items.');
    }

    final Object? rawHasMore = json['has_more'];

    if (rawHasMore is! bool) {
      throw const FormatException('Invalid Watch History has_more.');
    }

    final String? nextCursor = _optionalString(json['next_cursor']);

    return WatchHistoryPageDto(
      items: rawItems
          .map((dynamic item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('Invalid Watch History item.');
            }

            return WatchHistoryItemDto.fromJson(item);
          })
          .toList(growable: false),
      nextCursor: nextCursor,
      hasMore: rawHasMore,
    );
  }

  final List<WatchHistoryItemDto> items;
  final String? nextCursor;
  final bool hasMore;

  WatchHistoryPage toDomain() {
    return WatchHistoryPage(
      items: items
          .map((WatchHistoryItemDto item) => item.toDomain())
          .toList(growable: false),
      nextCursor: nextCursor,
      hasMore: hasMore,
    );
  }
}

String? _optionalString(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is! String) {
    throw const FormatException('Invalid optional string.');
  }

  final String normalized = value.trim();

  return normalized.isEmpty ? null : normalized;
}
