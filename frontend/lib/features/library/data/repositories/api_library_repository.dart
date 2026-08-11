import 'package:dio/dio.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/data/models/imported_library_media_dto.dart';
import 'package:sofawatch/features/library/data/models/library_entry_dto.dart';
import 'package:sofawatch/features/library/domain/models/imported_library_media.dart';
import 'package:sofawatch/features/library/domain/models/library_entry.dart';
import 'package:sofawatch/features/library/domain/models/library_media_type.dart';
import 'package:sofawatch/features/library/domain/repositories/library_repository.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';

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

  @override
  Future<void> removeShow(String showId) {
    return _removeFromLibrary('/library/shows/$showId');
  }

  @override
  Future<void> removeMovie(String movieId) {
    return _removeFromLibrary('/library/movies/$movieId');
  }

  @override
  Future<LibraryEntry> updateShowStatus(String showId, LibraryStatus status) {
    return _updateStatus(path: '/library/shows/$showId/status', status: status);
  }

  @override
  Future<LibraryEntry> updateMovieStatus(String movieId, LibraryStatus status) {
    return _updateStatus(
      path: '/library/movies/$movieId/status',
      status: status,
    );
  }

  @override
  Future<LibraryEntry?> getShowEntry(String showId) {
    return _getLibraryEntry('/library/shows/$showId');
  }

  @override
  Future<LibraryEntry?> getMovieEntry(String movieId) {
    return _getLibraryEntry('/library/movies/$movieId');
  }

  Future<LibraryEntry?> _getLibraryEntry(String path) async {
    try {
      final Response<Map<String, dynamic>> response = await _apiClient
          .get<Map<String, dynamic>>(path);

      final Map<String, dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException('The library response body is missing.');
      }

      return LibraryEntryDto.fromJson(data).toDomain();
    } on AppException catch (error) {
      if (error.code == 'library_entry_not_found') {
        return null;
      }

      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
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

  Future<void> _removeFromLibrary(String path) async {
    await _apiClient.delete<void>(path);
  }

  Future<LibraryEntry> _updateStatus({
    required String path,
    required LibraryStatus status,
  }) async {
    try {
      final Response<Map<String, dynamic>> response = await _apiClient
          .patch<Map<String, dynamic>>(
            path,
            data: <String, dynamic>{'status': status.name},
          );

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
