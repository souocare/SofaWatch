import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/domain/models/library_media_type.dart';

abstract final class LibraryFailureMessageMapper {
  static String messageFor(
    AppException error, {
    required LibraryMediaType mediaType,
  }) {
    final String target = switch (mediaType) {
      LibraryMediaType.show => 'Library',
      LibraryMediaType.movie => 'Watchlist',
    };

    return switch (error.type) {
      AppExceptionType.connection =>
        'Could not connect to the server. Check your connection and try again.',

      AppExceptionType.connectionTimeout ||
      AppExceptionType.sendTimeout ||
      AppExceptionType.receiveTimeout =>
        'The request took too long. Try again.',

      AppExceptionType.badCertificate =>
        'A secure connection to the server could not be established.',

      AppExceptionType.cancelled => 'The request was cancelled.',

      AppExceptionType.unauthorized || AppExceptionType.forbidden =>
        'You do not have permission to update your $target.',

      AppExceptionType.notFound => 'This item is no longer available.',

      AppExceptionType.conflict =>
        'This item could not be added to your $target.',

      AppExceptionType.validation => 'The request could not be completed.',

      AppExceptionType.server =>
        'The server could not update your $target. Try again.',

      AppExceptionType.badResponse || AppExceptionType.invalidData =>
        'The server returned an unexpected response.',

      AppExceptionType.unknown =>
        'Something went wrong while updating your $target.',
    };
  }
}
