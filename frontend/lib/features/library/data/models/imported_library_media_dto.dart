import 'package:sofawatch/features/library/domain/models/imported_library_media.dart';
import 'package:sofawatch/features/library/domain/models/library_media_type.dart';

final class ImportedLibraryMediaDto {
  const ImportedLibraryMediaDto({required this.id, required this.tmdbId});

  factory ImportedLibraryMediaDto.fromJson(Map<String, dynamic> json) {
    return ImportedLibraryMediaDto(
      id: _requiredString(json, 'id'),
      tmdbId: _requiredPositiveInt(json, 'tmdb_id'),
    );
  }

  final String id;
  final int tmdbId;

  ImportedLibraryMedia toDomain({required LibraryMediaType mediaType}) {
    return ImportedLibraryMedia(id: id, tmdbId: tmdbId, mediaType: mediaType);
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final Object? value = json[key];

    if (value is String && value.trim().isNotEmpty) {
      return value;
    }

    throw FormatException('Expected "$key" to be a non-empty string.');
  }

  static int _requiredPositiveInt(Map<String, dynamic> json, String key) {
    final Object? value = json[key];

    if (value is int && value > 0) {
      return value;
    }

    throw FormatException('Expected "$key" to be a positive integer.');
  }
}
