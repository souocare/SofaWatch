import 'package:sofawatch/features/server/domain/models/background_job.dart';
import 'package:sofawatch/features/server/domain/models/server_health.dart';
import 'package:sofawatch/features/server/domain/models/server_logs.dart';

abstract interface class ServerRepository {
  Future<ServerHealth> getHealth();

  Future<List<BackgroundJob>> getBackgroundJobs();

  Future<BackgroundJob> runBackgroundJob(String jobKey, {bool force = false});

  Future<ServerLogsPage> getLogs({
    ServerLogLevel? level,
    int offset = 0,
    int limit = 50,
  });
}
