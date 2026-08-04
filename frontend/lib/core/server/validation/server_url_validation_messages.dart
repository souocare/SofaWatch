import 'package:sofawatch/core/server/validation/server_url_validation_result.dart';

abstract final class ServerUrlValidationMessages {
  static String forError(ServerUrlValidationError error) {
    return switch (error) {
      ServerUrlValidationError.empty => 'Enter the server address.',
      ServerUrlValidationError.invalidFormat => 'Enter a valid server address.',
      ServerUrlValidationError.unsupportedScheme =>
        'The address must start with http:// or https://.',
      ServerUrlValidationError.missingHost =>
        'The server address must include a host.',
      ServerUrlValidationError.containsCredentials =>
        'Do not include a username or password in the address.',
      ServerUrlValidationError.containsQuery =>
        'Remove query parameters from the server address.',
      ServerUrlValidationError.containsFragment =>
        'Remove the fragment from the server address.',
    };
  }
}
