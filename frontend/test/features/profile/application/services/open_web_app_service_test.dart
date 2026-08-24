import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/navigation/web_app_launcher.dart';
import 'package:sofawatch/features/auth/domain/models/auth_handoff.dart';
import 'package:sofawatch/features/auth/domain/models/auth_session.dart';
import 'package:sofawatch/features/auth/domain/repositories/auth_handoff_repository.dart';
import 'package:sofawatch/features/profile/application/services/open_web_app_service.dart';

void main() {
  group('OpenWebAppService', () {
    test('returns false when SofaWatch server is not configured', () async {
      final _FakeAuthHandoffRepository repository =
          _FakeAuthHandoffRepository();

      final _FakeWebAppLauncher launcher = _FakeWebAppLauncher();

      final OpenWebAppService service = OpenWebAppService(
        apiClient: ApiClient(),
        authHandoffRepository: repository,
        launcher: launcher,
      );

      final bool opened = await service.open();

      expect(opened, isFalse);
      expect(repository.createCalls, 0);
      expect(launcher.openCalls, 0);
    });

    test('creates handoff before opening SofaWatch Web', () async {
      final _FakeAuthHandoffRepository repository = _FakeAuthHandoffRepository(
        handoff: const AuthHandoff(
          token: 'temporary-handoff-token',
          expiresIn: Duration(minutes: 2),
        ),
      );

      final _FakeWebAppLauncher launcher = _FakeWebAppLauncher();

      final OpenWebAppService service = OpenWebAppService(
        apiClient: ApiClient(
          baseUrl: Uri.parse('https://sofawatch.example.com'),
        ),
        authHandoffRepository: repository,
        launcher: launcher,
      );

      final bool opened = await service.open();

      expect(opened, isTrue);
      expect(repository.createCalls, 1);
      expect(launcher.openCalls, 1);
    });

    test('opens Web handoff URL containing only temporary token', () async {
      final _FakeAuthHandoffRepository repository = _FakeAuthHandoffRepository(
        handoff: const AuthHandoff(
          token: 'temporary-handoff-token',
          expiresIn: Duration(minutes: 2),
        ),
      );

      final _FakeWebAppLauncher launcher = _FakeWebAppLauncher();

      final OpenWebAppService service = OpenWebAppService(
        apiClient: ApiClient(
          baseUrl: Uri.parse('https://sofawatch.example.com'),
        ),
        authHandoffRepository: repository,
        launcher: launcher,
      );

      await service.open();

      expect(
        launcher.lastUri,
        Uri.parse(
          'https://sofawatch.example.com/auth/handoff'
          '?token=temporary-handoff-token',
        ),
      );

      expect(launcher.lastUri?.queryParameters.keys, <String>['token']);

      expect(launcher.lastUri.toString(), isNot(contains('access_token')));

      expect(launcher.lastUri.toString(), isNot(contains('refresh_token')));
    });

    test('preserves configured server origin', () async {
      final _FakeAuthHandoffRepository repository = _FakeAuthHandoffRepository(
        handoff: const AuthHandoff(
          token: 'handoff-token',
          expiresIn: Duration(minutes: 2),
        ),
      );

      final _FakeWebAppLauncher launcher = _FakeWebAppLauncher();

      final OpenWebAppService service = OpenWebAppService(
        apiClient: ApiClient(
          baseUrl: Uri.parse('https://server.example.com:8443'),
        ),
        authHandoffRepository: repository,
        launcher: launcher,
      );

      await service.open();

      expect(launcher.lastUri?.scheme, 'https');

      expect(launcher.lastUri?.host, 'server.example.com');

      expect(launcher.lastUri?.port, 8443);
    });

    test('returns false when launcher cannot open Web application', () async {
      final _FakeAuthHandoffRepository repository = _FakeAuthHandoffRepository(
        handoff: const AuthHandoff(
          token: 'temporary-handoff-token',
          expiresIn: Duration(minutes: 2),
        ),
      );

      final _FakeWebAppLauncher launcher = _FakeWebAppLauncher(result: false);

      final OpenWebAppService service = OpenWebAppService(
        apiClient: ApiClient(
          baseUrl: Uri.parse('https://sofawatch.example.com'),
        ),
        authHandoffRepository: repository,
        launcher: launcher,
      );

      final bool opened = await service.open();

      expect(opened, isFalse);
      expect(repository.createCalls, 1);
      expect(launcher.openCalls, 1);
    });
  });
}

final class _FakeAuthHandoffRepository implements AuthHandoffRepository {
  _FakeAuthHandoffRepository({
    this.handoff = const AuthHandoff(
      token: 'handoff-token',
      expiresIn: Duration(minutes: 2),
    ),
  });

  final AuthHandoff handoff;

  int createCalls = 0;

  @override
  Future<AuthHandoff> create() async {
    createCalls += 1;

    return handoff;
  }

  @override
  Future<AuthSession> exchange(String token) {
    throw UnimplementedError();
  }
}

final class _FakeWebAppLauncher implements WebAppLauncher {
  _FakeWebAppLauncher({this.result = true});

  final bool result;

  int openCalls = 0;
  Uri? lastUri;

  @override
  Future<bool> open(Uri uri) async {
    openCalls += 1;
    lastUri = uri;

    return result;
  }
}
