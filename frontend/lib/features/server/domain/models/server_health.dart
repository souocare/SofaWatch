import 'package:equatable/equatable.dart';

enum ServerHealthStatus { healthy, degraded, unavailable }

enum ServerComponentStatus { healthy, unavailable }

enum ServerDatabaseCheckStatus { ok, failed, unavailable }

final class ServerDatabaseHealth extends Equatable {
  const ServerDatabaseHealth({
    required this.status,
    required this.engine,
    required this.integrityCheck,
    required this.foreignKeyCheck,
    required this.migration,
    this.latencyMs,
    this.sizeBytes,
    this.walSizeBytes,
  });

  final ServerComponentStatus status;
  final String engine;

  final double? latencyMs;
  final int? sizeBytes;
  final int? walSizeBytes;

  final ServerDatabaseCheckStatus integrityCheck;
  final ServerDatabaseCheckStatus foreignKeyCheck;

  final ServerDatabaseMigration migration;

  bool get isHealthy {
    return status == ServerComponentStatus.healthy;
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    engine,
    latencyMs,
    sizeBytes,
    walSizeBytes,
    integrityCheck,
    foreignKeyCheck,
    migration,
  ];
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

final class ServerDatabaseMigration extends Equatable {
  const ServerDatabaseMigration({
    required this.revision,
    required this.message,
  });

  final String? revision;
  final String? message;

  @override
  List<Object?> get props => <Object?>[revision, message];
}
