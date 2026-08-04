import 'package:sofawatch/core/server/models/server_configuration.dart';

abstract interface class ServerConfigurationRepository {
  Future<ServerConfiguration?> load();

  Future<void> save(ServerConfiguration configuration);

  Future<void> clear();
}
