import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/server/validation/server_url_validation_result.dart';
import 'package:sofawatch/core/server/validation/server_url_validator.dart';

void main() {
  group('ServerUrlValidator', () {
    test('rejects an empty address', () {
      final ServerUrlValidationResult result = ServerUrlValidator.validate(
        '   ',
      );

      expect(result.isValid, isFalse);

      expect(result.error, ServerUrlValidationError.empty);
    });

    test('accepts an HTTPS address', () {
      final ServerUrlValidationResult result = ServerUrlValidator.validate(
        'https://sofawatch.example.com',
      );

      expect(result.isValid, isTrue);

      expect(result.uri, Uri.parse('https://sofawatch.example.com'));
    });

    test('accepts an HTTP address with an IP and port', () {
      final ServerUrlValidationResult result = ServerUrlValidator.validate(
        'http://192.168.1.99:8000',
      );

      expect(result.isValid, isTrue);

      expect(result.uri, Uri.parse('http://192.168.1.99:8000'));
    });

    test('accepts localhost', () {
      final ServerUrlValidationResult result = ServerUrlValidator.validate(
        'http://localhost:8000',
      );

      expect(result.isValid, isTrue);
    });

    test('accepts a local hostname', () {
      final ServerUrlValidationResult result = ServerUrlValidator.validate(
        'http://nas.local:8000',
      );

      expect(result.isValid, isTrue);
    });

    test('normalizes whitespace and trailing slashes', () {
      final ServerUrlValidationResult result = ServerUrlValidator.validate(
        '  HTTPS://Server.Example.com///  ',
      );

      expect(result.uri, Uri.parse('https://server.example.com'));
    });

    test('preserves a server base path', () {
      final ServerUrlValidationResult result = ServerUrlValidator.validate(
        'https://example.com/sofawatch/',
      );

      expect(result.uri, Uri.parse('https://example.com/sofawatch'));
    });

    test('rejects an address without a supported scheme', () {
      final ServerUrlValidationResult result = ServerUrlValidator.validate(
        '192.168.1.99:8000',
      );

      expect(result.isValid, isFalse);

      expect(result.error, ServerUrlValidationError.unsupportedScheme);
    });

    test('rejects an unsupported scheme', () {
      final ServerUrlValidationResult result = ServerUrlValidator.validate(
        'ftp://example.com',
      );

      expect(result.error, ServerUrlValidationError.unsupportedScheme);
    });

    test('rejects an address without a host', () {
      final ServerUrlValidationResult result = ServerUrlValidator.validate(
        'https://',
      );

      expect(result.error, ServerUrlValidationError.missingHost);
    });

    test('rejects credentials embedded in the address', () {
      final ServerUrlValidationResult result = ServerUrlValidator.validate(
        'https://user:password@example.com',
      );

      expect(result.error, ServerUrlValidationError.containsCredentials);
    });

    test('rejects query parameters', () {
      final ServerUrlValidationResult result = ServerUrlValidator.validate(
        'https://example.com?token=value',
      );

      expect(result.error, ServerUrlValidationError.containsQuery);
    });

    test('rejects fragments', () {
      final ServerUrlValidationResult result = ServerUrlValidator.validate(
        'https://example.com#section',
      );

      expect(result.error, ServerUrlValidationError.containsFragment);
    });
  });
}
