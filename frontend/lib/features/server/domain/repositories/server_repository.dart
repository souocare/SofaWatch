import 'package:sofawatch/features/server/domain/models/server_health.dart';

abstract interface class ServerRepository {
  Future<ServerHealth> getHealth();
}
