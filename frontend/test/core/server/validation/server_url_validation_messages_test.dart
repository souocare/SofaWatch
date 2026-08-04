import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/server/validation/server_url_validation_messages.dart';
import 'package:sofawatch/core/server/validation/server_url_validation_result.dart';

void main() {
  test('returns a message for every validation error', () {
    for (final ServerUrlValidationError error
        in ServerUrlValidationError.values) {
      expect(ServerUrlValidationMessages.forError(error), isNotEmpty);
    }
  });
}
