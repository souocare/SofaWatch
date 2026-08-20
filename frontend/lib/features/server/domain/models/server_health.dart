import 'package:equatable/equatable.dart';

enum ServerHealthStatus { healthy, degraded, unavailable }

enum ServerComponentStatus { healthy, unavailable }

final class ServerDatabaseHealth extends Equatable {
  const ServerDatabaseHealth({required this.status, this.latencyMs});

  final ServerComponentStatus status;
  final double? latencyMs;

  bool get isHealthy {
    return status == ServerComponentStatus.healthy;
  }

  @override
  List<Object?> get props => <Object?>[status, latencyMs];
}

final class ServerTmdbHealth extends Equatable {
  const ServerTmdbHealth({
    required this.status,
    required this.configured,
    this.latencyMs,
  });

  final ServerComponentStatus status;
  final bool configured;
  final double? latencyMs;

  bool get isHealthy {
    return status == ServerComponentStatus.healthy;
  }

  @override
  List<Object?> get props => <Object?>[status, configured, latencyMs];
}

final class ServerHealth extends Equatable {
  const ServerHealth({
    required this.status,
    required this.checkedAt,
    required this.uptimeSeconds,
    required this.database,
    required this.tmdb,
  });

  final ServerHealthStatus status;

  final DateTime checkedAt;

  final int uptimeSeconds;

  final ServerDatabaseHealth database;
  final ServerTmdbHealth tmdb;

  bool get isHealthy {
    return status == ServerHealthStatus.healthy;
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    checkedAt,
    uptimeSeconds,
    database,
    tmdb,
  ];
}
