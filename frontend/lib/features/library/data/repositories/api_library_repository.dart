import 'package:dio/dio.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/data/models/imported_library_media_dto.dart';
import 'package:sofawatch/features/library/data/models/library_entry_dto.dart';
import 'package:sofawatch/features/library/domain/models/imported_library_media.dart';
import 'package:sofawatch/features/library/domain/models/library_entry.dart';
import 'package:sofawatch/features/library/domain/models/library_media_type.dart';
import 'package:sofawatch/features/library/domain/repositories/library_repository.dart';

final class ApiLibraryRepository implements LibraryRepository {
  const ApiLibraryRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<ImportedLibraryMedia> importShowByTmdbId(int tmdbId) {
    return _importMedia(
      path: '/shows/import/tmdb/$tmdbId',
      mediaType: LibraryMediaType.show,
    );
  }

  @override
  Future<ImportedLibraryMedia> importMovieByTmdbId(int tmdbId) {
    return _importMedia(
      path: '/movies/import/tmdb/$tmdbId',
      mediaType: LibraryMediaType.movie,
    );
  }

  @override
  Future<LibraryEntry> addShow(String showId) {
    return _addToLibrary('/library/shows/$showId');
  }

  @override
  Future<LibraryEntry> addMovie(String movieId) {
    return _addToLibrary('/library/movies/$movieId');
  }

  Future<ImportedLibraryMedia> _importMedia({
    required String path,
    required LibraryMediaType mediaType,
  }) async {
    try {
      final Response<Map<String, dynamic>> response = await _apiClient
          .post<Map<String, dynamic>>(path);

      final Map<String, dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException(
          'The imported media response body is missing.',
        );
      }

      return ImportedLibraryMediaDto.fromJson(
        data,
      ).toDomain(mediaType: mediaType);
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }

  Future<LibraryEntry> _addToLibrary(String path) async {
    try {
      final Response<Map<String, dynamic>> response = await _apiClient
          .post<Map<String, dynamic>>(path);

      final Map<String, dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException('The library response body is missing.');
      }

      return LibraryEntryDto.fromJson(data).toDomain();
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }
}
