import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/core/server/models/server_configuration.dart';
import 'package:sofawatch/core/server/repositories/server_configuration_repository.dart';
import 'package:sofawatch/features/server_setup/application/cubit/server_setup_cubit.dart';
import 'package:sofawatch/features/server_setup/application/cubit/server_setup_state.dart';
import 'package:sofawatch/features/server_setup/domain/services/server_connection_tester.dart';

class _FakeServerConfigurationRepository
    implements ServerConfigurationRepository {
  ServerConfiguration? savedConfiguration;

  @override
  Future<ServerConfiguration?> load() async {
    return savedConfiguration;
  }

  @override
  Future<void> save(ServerConfiguration configuration) async {
    savedConfiguration = configuration;
  }

  @override
  Future<void> clear() async {
    savedConfiguration = null;
  }
}

class _FakeServerConnectionTester implements ServerConnectionTester {
  Object? errorToThrow;
  Uri? testedUrl;

  @override
  Future<void> testConnection(Uri serverUrl) async {
    testedUrl = serverUrl;

    final Object? error = errorToThrow;

    if (error != null) {
      throw error;
    }
  }
}

void main() {
  group('ServerSetupCubit', () {
    late _FakeServerConfigurationRepository repository;
    late _FakeServerConnectionTester connectionTester;
    late ApiClient apiClient;
    late ServerSetupCubit cubit;

    setUp(() {
      repository = _FakeServerConfigurationRepository();

      connectionTester = _FakeServerConnectionTester();

      apiClient = ApiClient();

      cubit = ServerSetupCubit(repository, connectionTester, apiClient);
    });

    tearDown(() async {
      await cubit.close();
    });

    test('starts with the initial state', () {
      expect(cubit.state, const ServerSetupState());
    });

    test('updates the server name', () {
      cubit.serverNameChanged('Home Server');

      expect(cubit.state.serverName, 'Home Server');
    });

    test('updates the server address', () {
      cubit.serverAddressChanged('https://server.example.com');

      expect(cubit.state.serverAddress, 'https://server.example.com');
    });

    test('updates the self-signed certificate preference', () {
      cubit.acceptSelfSignedCertificatesChanged(true);

      expect(cubit.state.acceptSelfSignedCertificates, isTrue);
    });

    test('reports validation errors for empty values', () async {
      await cubit.submit();

      expect(cubit.state.serverNameError, isNotNull);

      expect(cubit.state.serverUrlError, isNotNull);

      expect(cubit.state.failureType, isNull);

      expect(connectionTester.testedUrl, isNull);

      expect(repository.savedConfiguration, isNull);

      expect(apiClient.isConfigured, isFalse);
    });

    test('tests, saves and activates a valid server', () async {
      cubit
        ..serverNameChanged('Home Server')
        ..serverAddressChanged(' HTTPS://Server.Example.com/ ');

      await cubit.submit();

      final ServerConfiguration? configuration = repository.savedConfiguration;

      expect(cubit.state.status, ServerSetupStatus.success);

      expect(cubit.state.failureType, isNull);

      expect(cubit.state.failureMessage, isNull);

      expect(configuration, isNotNull);

      expect(configuration!.serverName, 'Home Server');

      expect(configuration.serverUrl, Uri.parse('https://server.example.com'));

      expect(connectionTester.testedUrl, configuration.serverUrl);

      expect(apiClient.isConfigured, isTrue);

      expect(apiClient.baseUrl, 'https://server.example.com/api/v1');
    });

    test('persists the self-signed certificate preference', () async {
      cubit
        ..serverNameChanged('Home Server')
        ..serverAddressChanged('https://server.example.com')
        ..acceptSelfSignedCertificatesChanged(true);

      await cubit.submit();

      expect(
        repository.savedConfiguration?.acceptSelfSignedCertificates,
        isTrue,
      );
    });

    test(
      'does not save or configure the client when connection fails',
      () async {
        connectionTester.errorToThrow = const AppException.connection();

        cubit
          ..serverNameChanged('Home Server')
          ..serverAddressChanged('https://server.example.com');

        await cubit.submit();

        expect(cubit.state.status, ServerSetupStatus.failure);

        expect(cubit.state.failureType, AppExceptionType.connection);

        expect(
          cubit.state.failureMessage,
          'Could not connect to the server. '
          'Check the address and your network connection.',
        );

        expect(repository.savedConfiguration, isNull);

        expect(apiClient.isConfigured, isFalse);
      },
    );

    test('shows a specific message when the connection times out', () async {
      connectionTester.errorToThrow = const AppException.connectionTimeout();

      cubit
        ..serverNameChanged('Home Server')
        ..serverAddressChanged('https://server.example.com');

      await cubit.submit();

      expect(cubit.state.status, ServerSetupStatus.failure);

      expect(cubit.state.failureType, AppExceptionType.connectionTimeout);

      expect(
        cubit.state.failureMessage,
        'The connection to the server timed out.',
      );

      expect(repository.savedConfiguration, isNull);

      expect(apiClient.isConfigured, isFalse);
    });

    test('shows a specific message for an invalid certificate', () async {
      connectionTester.errorToThrow = const AppException.badCertificate();

      cubit
        ..serverNameChanged('Home Server')
        ..serverAddressChanged('https://server.example.com');

      await cubit.submit();

      expect(cubit.state.failureType, AppExceptionType.badCertificate);

      expect(
        cubit.state.failureMessage,
        'The server certificate could not be verified.',
      );
    });

    test('shows a specific message for invalid server data', () async {
      connectionTester.errorToThrow = const AppException.invalidData();

      cubit
        ..serverNameChanged('Home Server')
        ..serverAddressChanged('https://server.example.com');

      await cubit.submit();

      expect(cubit.state.failureType, AppExceptionType.invalidData);

      expect(
        cubit.state.failureMessage,
        'The server returned data that SofaWatch could not understand.',
      );
    });

    test('shows a specific message when the server is unhealthy', () async {
      connectionTester.errorToThrow = const AppException(
        type: AppExceptionType.server,
        code: 'server_unhealthy',
        message: 'The server is not healthy.',
      );

      cubit
        ..serverNameChanged('Home Server')
        ..serverAddressChanged('https://server.example.com');

      await cubit.submit();

      expect(cubit.state.failureType, AppExceptionType.server);

      expect(
        cubit.state.failureMessage,
        'The SofaWatch server is reachable but is not currently healthy.',
      );
    });

    test('shows a safe message for an unexpected exception', () async {
      connectionTester.errorToThrow = Exception(
        'Internal technical information',
      );

      cubit
        ..serverNameChanged('Home Server')
        ..serverAddressChanged('https://server.example.com');

      await cubit.submit();

      expect(cubit.state.status, ServerSetupStatus.failure);

      expect(cubit.state.failureType, AppExceptionType.unknown);

      expect(cubit.state.failureMessage, 'An unexpected error occurred.');

      expect(
        cubit.state.failureMessage,
        isNot(contains('Internal technical information')),
      );
    });

    test(
      'clears the previous failure when the server address changes',
      () async {
        connectionTester.errorToThrow = const AppException.connection();

        cubit
          ..serverNameChanged('Home Server')
          ..serverAddressChanged('https://server.example.com');

        await cubit.submit();

        expect(cubit.state.failureType, AppExceptionType.connection);

        expect(cubit.state.failureMessage, isNotNull);

        cubit.serverAddressChanged('https://other.example.com');

        expect(cubit.state.status, ServerSetupStatus.initial);

        expect(cubit.state.failureType, isNull);

        expect(cubit.state.failureMessage, isNull);
      },
    );

    test('clears the previous failure when the server name changes', () async {
      connectionTester.errorToThrow = const AppException.connection();

      cubit
        ..serverNameChanged('Home Server')
        ..serverAddressChanged('https://server.example.com');

      await cubit.submit();

      expect(cubit.state.failureType, AppExceptionType.connection);

      cubit.serverNameChanged('Another Server');

      expect(cubit.state.failureType, isNull);

      expect(cubit.state.failureMessage, isNull);
    });

    blocTest<ServerSetupCubit, ServerSetupState>(
      'emits a new state when the server name changes',
      build: () {
        return ServerSetupCubit(
          _FakeServerConfigurationRepository(),
          _FakeServerConnectionTester(),
          ApiClient(),
        );
      },
      act: (ServerSetupCubit cubit) {
        cubit.serverNameChanged('Home Server');
      },
      expect: () => <ServerSetupState>[
        const ServerSetupState(serverName: 'Home Server'),
      ],
    );

    blocTest<ServerSetupCubit, ServerSetupState>(
      'emits testing, saving and success for a valid server',
      build: () {
        return ServerSetupCubit(
          _FakeServerConfigurationRepository(),
          _FakeServerConnectionTester(),
          ApiClient(),
        );
      },
      seed: () => const ServerSetupState(
        serverName: 'Home Server',
        serverAddress: 'https://server.example.com',
      ),
      act: (ServerSetupCubit cubit) async {
        await cubit.submit();
      },
      expect: () => <Matcher>[
        isA<ServerSetupState>().having(
          (ServerSetupState state) => state.status,
          'status',
          ServerSetupStatus.testing,
        ),
        isA<ServerSetupState>().having(
          (ServerSetupState state) => state.status,
          'status',
          ServerSetupStatus.saving,
        ),
        isA<ServerSetupState>().having(
          (ServerSetupState state) => state.status,
          'status',
          ServerSetupStatus.success,
        ),
      ],
    );
  });
}
