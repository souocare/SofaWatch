import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/api/models/api_error_response.dart';

void main() {
  group('ApiErrorResponse', () {
    test('parses a standard API error', () {
      final ApiErrorResponse response = ApiErrorResponse.fromJson(
        <String, dynamic>{
          'error': <String, dynamic>{
            'code': 'show_not_found',
            'message': 'The show was not found.',
          },
        },
      );

      expect(response.error.code, 'show_not_found');

      expect(response.error.message, 'The show was not found.');

      expect(response.error.details, isNull);
    });

    test('parses validation error details', () {
      final ApiErrorResponse response = ApiErrorResponse.fromJson(
        <String, dynamic>{
          'error': <String, dynamic>{
            'code': 'validation_error',
            'message': 'The request contains invalid data.',
            'details': <Map<String, dynamic>>[
              <String, dynamic>{
                'field': 'query',
                'message': 'Invalid value.',
                'context': <String, dynamic>{'minimum': 1},
              },
            ],
          },
        },
      );

      final ApiErrorDetail detail = response.error.details!.single;

      expect(detail.field, 'query');

      expect(detail.message, 'Invalid value.');

      expect(detail.context, <String, dynamic>{'minimum': 1});
    });

    test('rejects a response without an error object', () {
      expect(
        () => ApiErrorResponse.fromJson(<String, dynamic>{
          'message': 'Invalid response',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('ignores malformed detail entries', () {
      final ApiErrorResponse response = ApiErrorResponse.fromJson(
        <String, dynamic>{
          'error': <String, dynamic>{
            'code': 'validation_error',
            'message': 'The request contains invalid data.',
            'details': <dynamic>[
              'invalid',
              <String, dynamic>{'field': 'name', 'message': 'Required.'},
            ],
          },
        },
      );

      expect(response.error.details, hasLength(1));
    });

    test('rejects an error without a code', () {
      expect(
        () => ApiErrorResponse.fromJson(<String, dynamic>{
          'error': <String, dynamic>{'message': 'Invalid request.'},
        }),
        throwsA(isA<TypeError>()),
      );
    });

    test('rejects an error without a message', () {
      expect(
        () => ApiErrorResponse.fromJson(<String, dynamic>{
          'error': <String, dynamic>{'code': 'invalid_request'},
        }),
        throwsA(isA<TypeError>()),
      );
    });

    test('ignores details when they are not a list', () {
      final ApiErrorResponse response = ApiErrorResponse.fromJson(
        <String, dynamic>{
          'error': <String, dynamic>{
            'code': 'validation_error',
            'message': 'Invalid request.',
            'details': 'unexpected',
          },
        },
      );

      expect(response.error.details, isNull);
    });

    test('ignores malformed detail context', () {
      final ApiErrorResponse response = ApiErrorResponse.fromJson(
        <String, dynamic>{
          'error': <String, dynamic>{
            'code': 'validation_error',
            'message': 'Invalid request.',
            'details': <Map<String, dynamic>>[
              <String, dynamic>{
                'field': 'query',
                'message': 'Invalid value.',
                'context': 'unexpected',
              },
            ],
          },
        },
      );

      expect(response.error.details!.single.context, isNull);
    });
  });
}
