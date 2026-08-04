import 'package:sofawatch/core/server/validation/server_url_validation_result.dart';

abstract final class ServerUrlValidator {
  static const Set<String> _supportedSchemes = <String>{'http', 'https'};

  static ServerUrlValidationResult validate(String value) {
    final String normalizedInput = value.trim();

    if (normalizedInput.isEmpty) {
      return const ServerUrlValidationResult.invalid(
        ServerUrlValidationError.empty,
      );
    }

    final bool hasExplicitScheme = RegExp(
      r'^[a-zA-Z][a-zA-Z0-9+.-]*://',
    ).hasMatch(normalizedInput);

    if (!hasExplicitScheme) {
      return const ServerUrlValidationResult.invalid(
        ServerUrlValidationError.unsupportedScheme,
      );
    }

    final Uri? parsedUri = Uri.tryParse(normalizedInput);

    if (parsedUri == null) {
      return const ServerUrlValidationResult.invalid(
        ServerUrlValidationError.invalidFormat,
      );
    }

    final String scheme = parsedUri.scheme.toLowerCase();

    if (!_supportedSchemes.contains(scheme)) {
      return const ServerUrlValidationResult.invalid(
        ServerUrlValidationError.unsupportedScheme,
      );
    }

    if (parsedUri.host.trim().isEmpty) {
      return const ServerUrlValidationResult.invalid(
        ServerUrlValidationError.missingHost,
      );
    }

    if (parsedUri.userInfo.isNotEmpty) {
      return const ServerUrlValidationResult.invalid(
        ServerUrlValidationError.containsCredentials,
      );
    }

    if (parsedUri.hasQuery) {
      return const ServerUrlValidationResult.invalid(
        ServerUrlValidationError.containsQuery,
      );
    }

    if (parsedUri.hasFragment) {
      return const ServerUrlValidationResult.invalid(
        ServerUrlValidationError.containsFragment,
      );
    }

    return ServerUrlValidationResult.valid(_normalize(parsedUri));
  }

  static Uri _normalize(Uri uri) {
    final String normalizedPath = uri.path.replaceFirst(RegExp(r'/+$'), '');

    return uri.replace(
      scheme: uri.scheme.toLowerCase(),
      host: uri.host.toLowerCase(),
      path: normalizedPath,
      query: null,
      fragment: null,
    );
  }
}
