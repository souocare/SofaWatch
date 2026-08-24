import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/security/data/repositories/api_security_settings_repository.dart';
import 'package:sofawatch/features/security/domain/models/security_settings.dart';

void main() {
  group('ApiSecuritySettingsRepository', () {
    late ApiClient apiClient;
    late DioAdapter dioAdapter;
    late ApiSecuritySettingsRepository repository;

    setUp(() {
      apiClient = ApiClient(baseUrl: Uri.parse('http://localhost:8000'));

      dioAdapter = DioAdapter(dio: apiClient.dio, printLogs: false);

      repository = ApiSecuritySettingsRepository(apiClient: apiClient);
    });

    test('loads Security settings', () async {
      dioAdapter.onGet('/security', (server) {
        server.reply(200, <String, dynamic>{'open_registration': false});
      });

      final SecuritySettings result = await repository.getSettings();

      expect(result, const SecuritySettings(openRegistration: false));
    });

    test('updates Open registration', () async {
      dioAdapter.onPatch(
        '/security',
        data: <String, dynamic>{'open_registration': true},
        (server) {
          server.reply(200, <String, dynamic>{'open_registration': true});
        },
      );

      final SecuritySettings result = await repository.updateOpenRegistration(
        enabled: true,
      );

      expect(result.openRegistration, isTrue);
    });

    test('maps malformed response to invalidData', () async {
      dioAdapter.onGet('/security', (server) {
        server.reply(200, <String, dynamic>{'open_registration': 'false'});
      });

      expect(
        repository.getSettings(),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('maps missing response body to invalidData', () async {
      dioAdapter.onGet('/security', (server) {
        server.reply(200, null);
      });

      expect(
        repository.getSettings(),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('propagates API errors unchanged', () async {
      dioAdapter.onGet('/security', (server) {
        server.reply(403, <String, dynamic>{
          'error': <String, dynamic>{
            'code': 'admin_required',
            'message': 'Administrator access is required.',
          },
        });
      });

      expect(
        repository.getSettings(),
        throwsA(
          isA<AppException>()
              .having(
                (AppException error) => error.type,
                'type',
                AppExceptionType.forbidden,
              )
              .having(
                (AppException error) => error.code,
                'code',
                'admin_required',
              ),
        ),
      );
    });
  });
}
