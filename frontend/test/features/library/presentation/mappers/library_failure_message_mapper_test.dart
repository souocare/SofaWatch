import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/domain/models/library_media_type.dart';
import 'package:sofawatch/features/library/presentation/mappers/library_failure_message_mapper.dart';

void main() {
  group('LibraryFailureMessageMapper', () {
    test('maps a connection failure to a safe message', () {
      const AppException error = AppException.connection(
        originalError: 'technical network details',
      );

      final String message = LibraryFailureMessageMapper.messageFor(
        error,
        mediaType: LibraryMediaType.show,
      );

      expect(
        message,
        'Could not connect to the server. '
        'Check your connection and try again.',
      );

      expect(message, isNot(contains('technical network details')));
    });

    test('uses Watchlist terminology for Movie failures', () {
      const AppException error = AppException.unknown();

      expect(
        LibraryFailureMessageMapper.messageFor(
          error,
          mediaType: LibraryMediaType.movie,
        ),
        'Something went wrong while updating your Watchlist.',
      );
    });

    test('maps timeout failures without exposing provider details', () {
      const AppException error = AppException.receiveTimeout();

      expect(
        LibraryFailureMessageMapper.messageFor(
          error,
          mediaType: LibraryMediaType.show,
        ),
        'The request took too long. Try again.',
      );
    });
  });
}
