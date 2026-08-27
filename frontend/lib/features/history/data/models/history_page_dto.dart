import 'package:sofawatch/features/history/data/models/history_episode_item_dto.dart';
import 'package:sofawatch/features/history/data/models/history_movie_item_dto.dart';
import 'package:sofawatch/features/history/domain/models/history_item.dart';
import 'package:sofawatch/features/history/domain/models/history_page.dart';

final class HistoryPageDto {
  const HistoryPageDto({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  factory HistoryPageDto.fromJson(Map<String, dynamic> json) {
    final Object? rawItems = json['items'];

    if (rawItems is! List<dynamic>) {
      throw const FormatException('History items must be a list.');
    }

    final List<Object> items = rawItems
        .map((dynamic item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('History items must contain objects.');
          }

          final Object? mediaType = item['media_type'];

          return switch (mediaType) {
            'episode' => HistoryEpisodeItemDto.fromJson(item),
            'movie' => HistoryMovieItemDto.fromJson(item),
            _ => throw const FormatException('Invalid History media_type.'),
          };
        })
        .toList(growable: false);

    final Object? rawHasMore = json['has_more'];

    if (rawHasMore is! bool) {
      throw const FormatException('History has_more must be a boolean.');
    }

    return HistoryPageDto(
      items: items,
      nextCursor: _optionalString(json['next_cursor']),
      hasMore: rawHasMore,
    );
  }

  final List<Object> items;
  final String? nextCursor;
  final bool hasMore;

  HistoryPage toDomain({required String Function(String path) resolveUrl}) {
    return HistoryPage(
      items: items
          .map(
            (Object item) => switch (item) {
              HistoryEpisodeItemDto episode => episode.toDomain(
                resolveUrl: resolveUrl,
              ),
              HistoryMovieItemDto movie => movie.toDomain(
                resolveUrl: resolveUrl,
              ),
              _ => throw const FormatException('Unsupported History DTO.'),
            },
          )
          .cast<HistoryItem>()
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

  if (value is! String || value.trim().isEmpty) {
    throw const FormatException(
      'next_cursor must be null or a non-empty string.',
    );
  }

  return value.trim();
}
