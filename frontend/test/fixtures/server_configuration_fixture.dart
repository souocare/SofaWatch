import 'package:sofawatch/core/server/models/server_configuration.dart';

import '../helpers/test_constants.dart';

ServerConfiguration createServerConfigurationFixture({
  String serverName = TestConstants.serverName,
  Uri? serverUrl,
  bool acceptSelfSignedCertificates = false,
}) {
  return ServerConfiguration(
    serverName: serverName,
    serverUrl: serverUrl ?? TestConstants.serverUrl,
    acceptSelfSignedCertificates: acceptSelfSignedCertificates,
  );
}
