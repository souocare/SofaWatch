import 'package:sofawatch/core/errors/app_exception.dart';

abstract final class AppErrorMessageMapper {
  static String map(AppException exception) {
    if (exception.code != null) {
      final String? codeMessage = _messageForCode(exception.code!);

      if (codeMessage != null) {
        return codeMessage;
      }
    }

    return _messageForType(exception.type);
  }

  static String _messageForType(AppExceptionType type) {
    return switch (type) {
      AppExceptionType.connection =>
        'Could not connect to the server. Check the address and your network connection.',
      AppExceptionType.connectionTimeout =>
        'The connection to the server timed out.',
      AppExceptionType.sendTimeout => 'The request took too long to send.',
      AppExceptionType.receiveTimeout => 'The server took too long to respond.',
      AppExceptionType.badCertificate =>
        'The server certificate could not be verified.',
      AppExceptionType.cancelled => 'The request was cancelled.',
      AppExceptionType.unauthorized => 'You need to sign in to continue.',
      AppExceptionType.forbidden =>
        'You do not have permission to perform this action.',
      AppExceptionType.notFound => 'The requested content could not be found.',
      AppExceptionType.conflict =>
        'This action conflicts with the current server state.',
      AppExceptionType.validation =>
        'Some of the submitted information is invalid.',
      AppExceptionType.server => 'The SofaWatch server encountered an error.',
      AppExceptionType.badResponse =>
        'The server returned an unexpected response.',
      AppExceptionType.invalidData =>
        'The server returned data that SofaWatch could not understand.',
      AppExceptionType.unknown => 'An unexpected error occurred.',
    };
  }

  static String? _messageForCode(String code) {
    return switch (code) {
      'server_unhealthy' =>
        'The SofaWatch server is reachable but is not currently healthy.',
      'service_unavailable' =>
        'The SofaWatch service is temporarily unavailable.',
      'validation_error' => 'Some of the submitted information is invalid.',
      'show_not_found' => 'The requested TV show could not be found.',
      'season_not_found' => 'The requested season could not be found.',
      'episode_not_found' => 'The requested episode could not be found.',
      'episode_cannot_be_watched' =>
        'This episode cannot be marked as watched yet.',
      'movie_not_found' => 'The requested movie could not be found.',
      'library_entry_not_found' =>
        'This item could not be found in your library.',
      'background_job_not_found' =>
        'The requested background job could not be found.',
      'http_error' => null,
      _ => null,
    };
  }
}
