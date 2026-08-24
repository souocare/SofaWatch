import 'package:sofawatch/features/auth/domain/models/setup_status.dart';

abstract interface class SetupStatusRepository {
  Future<SetupStatus> getStatus();
}
