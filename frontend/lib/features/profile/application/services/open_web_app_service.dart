import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/navigation/web_app_launcher.dart';

final class OpenWebAppService {
  const OpenWebAppService({
    required ApiClient apiClient,
    required WebAppLauncher launcher,
  }) : _apiClient = apiClient,
       _launcher = launcher;

  final ApiClient _apiClient;
  final WebAppLauncher _launcher;

  Future<bool> open() async {
    final Uri? serverUri = _apiClient.serverUri;

    if (serverUri == null) {
      return false;
    }

    return _launcher.open(serverUri);
  }
}
