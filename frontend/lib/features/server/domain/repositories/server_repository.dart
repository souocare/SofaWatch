import 'package:sofawatch/features/server/domain/models/background_job.dart';
import 'package:sofawatch/features/server/domain/models/server_health.dart';

abstract interface class ServerRepository {
  Future<ServerHealth> getHealth();

  Future<List<BackgroundJob>> getBackgroundJobs();

  Future<BackgroundJob> runBackgroundJob(String jobKey);
}
