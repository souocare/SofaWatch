import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/server/models/server_configuration.dart';
import 'package:sofawatch/core/server/repositories/server_configuration_repository.dart';

class _InMemoryServerConfigurationRepository
    implements ServerConfigurationRepository {
  ServerConfiguration? _configuration;

  @override
  Future<ServerConfiguration?> load() async {
    return _configuration;
  }

  @override
  Future<void> save(ServerConfiguration configuration) async {
    _configuration = configuration;
  }

  @override
  Future<void> clear() async {
    _configuration = null;
  }
}

void main() {
  group('ServerConfigurationRepository contract', () {
    late ServerConfigurationRepository repository;

    setUp(() {
      repository = _InMemoryServerConfigurationRepository();
    });

    test('returns null when no configuration exists', () async {
      final ServerConfiguration? configuration = await repository.load();

      expect(configuration, isNull);
    });

    test('saves and loads a server configuration', () async {
      final ServerConfiguration expected = ServerConfiguration(
        serverName: 'Home Server',
        serverUrl: Uri.parse('https://sofawatch.example.com'),
      );

      await repository.save(expected);

      final ServerConfiguration? actual = await repository.load();

      expect(actual, expected);
    });

    test('replaces the existing configuration', () async {
      await repository.save(
        ServerConfiguration(
          serverName: 'Old Server',
          serverUrl: Uri.parse('https://old.example.com'),
        ),
      );

      final ServerConfiguration expected = ServerConfiguration(
        serverName: 'New Server',
        serverUrl: Uri.parse('https://new.example.com'),
      );

      await repository.save(expected);

      expect(await repository.load(), expected);
    });

    test('clears the saved configuration', () async {
      await repository.save(
        ServerConfiguration(
          serverName: 'Home Server',
          serverUrl: Uri.parse('https://sofawatch.example.com'),
        ),
      );

      await repository.clear();

      expect(await repository.load(), isNull);
    });
  });
}
