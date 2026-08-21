import 'package:url_launcher/url_launcher.dart';

abstract interface class WebAppLauncher {
  Future<bool> open(Uri uri);
}

final class ExternalWebAppLauncher implements WebAppLauncher {
  const ExternalWebAppLauncher();

  @override
  Future<bool> open(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
