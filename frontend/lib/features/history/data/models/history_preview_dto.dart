import 'package:sofawatch/features/history/data/models/history_episode_item_dto.dart';
import 'package:sofawatch/features/history/data/models/history_movie_item_dto.dart';
import 'package:sofawatch/features/history/domain/models/history_preview.dart';

final class HistoryPreviewDto {
  const HistoryPreviewDto({required this.episodes, required this.movies});

  factory HistoryPreviewDto.fromJson(Map<String, dynamic> json) {
    return HistoryPreviewDto(
      episodes: _parseList(
        json,
        key: 'episodes',
        parser: HistoryEpisodeItemDto.fromJson,
      ),
      movies: _parseList(
        json,
        key: 'movies',
        parser: HistoryMovieItemDto.fromJson,
      ),
    );
  }

  final List<HistoryEpisodeItemDto> episodes;
  final List<HistoryMovieItemDto> movies;

  HistoryPreview toDomain({required String Function(String path) resolveUrl}) {
    return HistoryPreview(
      episodes: episodes
          .map(
            (HistoryEpisodeItemDto item) =>
                item.toDomain(resolveUrl: resolveUrl),
          )
          .toList(growable: false),
      movies: movies
          .map(
            (HistoryMovieItemDto item) => item.toDomain(resolveUrl: resolveUrl),
          )
          .toList(growable: false),
    );
  }
}

List<T> _parseList<T>(
  Map<String, dynamic> json, {
  required String key,
  required T Function(Map<String, dynamic> json) parser,
}) {
  final Object? rawValue = json[key];

  if (rawValue is! List<dynamic>) {
    throw FormatException('$key must be a list.');
  }

  return rawValue
      .map((dynamic item) {
        if (item is! Map<String, dynamic>) {
          throw FormatException('$key must contain objects.');
        }

        return parser(item);
      })
      .toList(growable: false);
}
