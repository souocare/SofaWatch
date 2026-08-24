import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/navigation/web_app_launcher.dart';
import 'package:sofawatch/features/auth/domain/models/auth_handoff.dart';
import 'package:sofawatch/features/auth/domain/repositories/auth_handoff_repository.dart';

final class OpenWebAppService {
  const OpenWebAppService({
    required ApiClient apiClient,
    required AuthHandoffRepository authHandoffRepository,
    required WebAppLauncher launcher,
  }) : _apiClient = apiClient,
       _authHandoffRepository = authHandoffRepository,
       _launcher = launcher;

  final ApiClient _apiClient;
  final AuthHandoffRepository _authHandoffRepository;
  final WebAppLauncher _launcher;

  Future<bool> open() async {
    final Uri? serverUri = _apiClient.serverUri;

    if (serverUri == null) {
      return false;
    }

    final AuthHandoff handoff = await _authHandoffRepository.create();

    final Uri handoffUri = serverUri.replace(
      path: '/auth/handoff',
      queryParameters: <String, String>{'token': handoff.token},
      fragment: null,
    );

    return _launcher.open(handoffUri);
  }
}
