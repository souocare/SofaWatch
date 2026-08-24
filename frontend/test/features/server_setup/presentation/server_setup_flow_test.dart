@TestOn('vm')
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';

import '../../../fakes/fake_server_configuration_repository.dart';
import '../../../fakes/fake_server_connection_tester.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_bootstrap_data.dart';

void main() {
  group('Server Setup flow', () {
    late FakeServerConfigurationRepository repository;
    late FakeServerConnectionTester connectionTester;
    late ApiClient apiClient;

    setUp(() {
      repository = FakeServerConfigurationRepository();

      connectionTester = FakeServerConnectionTester();

      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                final String path = options.path;

                if (path.endsWith('/auth/session')) {
                  handler.resolve(
                    Response<Map<String, dynamic>>(
                      requestOptions: options,
                      statusCode: 200,
                      data: const <String, dynamic>{
                        'access_token': 'test-access-token',
                        'token_type': 'bearer',
                        'expires_in': 900,
                      },
                    ),
                  );

                  return;
                }

                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 500,
                    data: const <String, dynamic>{
                      'error': <String, dynamic>{
                        'code': 'test_unhandled_request',
                        'message': 'Unhandled test request.',
                      },
                    },
                  ),
                );
              },
        ),
      );

      apiClient = ApiClient(dio: dio);
    });

    testWidgets('shows Server Setup when no server is configured', (
      WidgetTester tester,
    ) async {
      await tester.pumpSofaWatchApp(
        bootstrapData: createTestBootstrapData(
          hasConfiguredServer: false,
          serverConfigurationRepository: repository,
          serverConnectionTester: connectionTester,
          apiClient: apiClient,
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('server-setup-page-title')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('server-name-field')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('server-address-field')),
        findsOneWidget,
      );
    });

    testWidgets('validates empty fields', (WidgetTester tester) async {
      await tester.pumpSofaWatchApp(
        bootstrapData: createTestBootstrapData(
          hasConfiguredServer: false,
          serverConfigurationRepository: repository,
          serverConnectionTester: connectionTester,
          apiClient: apiClient,
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('server-setup-submit-button')),
      );

      await tester.pumpAndSettle();

      expect(find.text('Enter a name for this server.'), findsOneWidget);

      expect(find.text('Enter the server address.'), findsOneWidget);

      expect(connectionTester.testedUrl, isNull);

      expect(connectionTester.callCount, 0);

      expect(repository.configuration, isNull);

      expect(repository.saveCallCount, 0);
    });

    testWidgets('connects, saves the server and opens Home', (
      WidgetTester tester,
    ) async {
      await tester.pumpSofaWatchApp(
        bootstrapData: createTestBootstrapData(
          hasConfiguredServer: false,
          serverConfigurationRepository: repository,
          serverConnectionTester: connectionTester,
          apiClient: apiClient,
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('server-name-field')),
        'Home Server',
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('server-address-field')),
        'https://server.example.com/',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('server-setup-submit-button')),
      );

      //
      // Do not use pumpAndSettle here.
      //
      // Completing Server Setup now triggers authentication
      // restoration and then mounts Home, whose independent
      // asynchronous sections can temporarily use indeterminate
      // progress indicators.
      //
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(connectionTester.callCount, 1);

      expect(
        connectionTester.testedUrl,
        Uri.parse('https://server.example.com'),
      );

      expect(repository.saveCallCount, 1);

      expect(repository.configuration, isNotNull);

      expect(repository.configuration?.serverName, 'Home Server');

      expect(apiClient.isConfigured, isTrue);

      expect(apiClient.baseUrl, 'https://server.example.com/api/v1');

      expect(find.byKey(const ValueKey<String>('home-page')), findsOneWidget);
    });

    testWidgets('shows an error when the connection fails', (
      WidgetTester tester,
    ) async {
      connectionTester.errorToThrow = const AppException.connection();

      await tester.pumpSofaWatchApp(
        bootstrapData: createTestBootstrapData(
          hasConfiguredServer: false,
          serverConfigurationRepository: repository,
          serverConnectionTester: connectionTester,
          apiClient: apiClient,
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('server-name-field')),
        'Home Server',
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('server-address-field')),
        'https://server.example.com',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('server-setup-submit-button')),
      );

      await tester.pumpAndSettle();

      expect(connectionTester.callCount, 1);

      expect(
        find.byKey(const ValueKey<String>('server-setup-failure-message')),
        findsOneWidget,
      );

      expect(
        find.text(
          'Could not connect to the server. '
          'Check the address and your network connection.',
        ),
        findsOneWidget,
      );

      expect(repository.configuration, isNull);

      expect(repository.saveCallCount, 0);

      expect(apiClient.isConfigured, isFalse);

      expect(
        find.byKey(const ValueKey<String>('server-setup-page-title')),
        findsOneWidget,
      );
    });
  });
}
