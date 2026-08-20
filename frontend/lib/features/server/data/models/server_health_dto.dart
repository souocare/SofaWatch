import 'package:sofawatch/features/server/domain/models/server_health.dart';

final class ServerHealthDto {
  const ServerHealthDto({
    required this.status,
    required this.checkedAt,
    required this.uptimeSeconds,
    required this.database,
    required this.tmdb,
  });

  factory ServerHealthDto.fromJson(Map<String, dynamic> json) {
    return ServerHealthDto(
      status: _parseHealthStatus(_requiredString(json, 'status')),
      checkedAt: _requiredDateTime(json, 'checked_at'),
      uptimeSeconds: _requiredNonNegativeInt(json, 'uptime_seconds'),
      database: ServerDatabaseHealthDto.fromJson(
        _requiredMap(json, 'database'),
      ),
      tmdb: ServerTmdbHealthDto.fromJson(_requiredMap(json, 'tmdb')),
    );
  }

  final ServerHealthStatus status;
  final DateTime checkedAt;
  final int uptimeSeconds;

  final ServerDatabaseHealthDto database;
  final ServerTmdbHealthDto tmdb;

  ServerHealth toDomain() {
    return ServerHealth(
      status: status,
      checkedAt: checkedAt,
      uptimeSeconds: uptimeSeconds,
      database: database.toDomain(),
      tmdb: tmdb.toDomain(),
    );
  }
}

final class ServerDatabaseHealthDto {
  const ServerDatabaseHealthDto({
    required this.status,
    required this.engine,
    required this.integrityCheck,
    required this.foreignKeyCheck,
    required this.migration,
    required this.latencyMs,
    required this.sizeBytes,
    required this.walSizeBytes,
  });

  factory ServerDatabaseHealthDto.fromJson(Map<String, dynamic> json) {
    return ServerDatabaseHealthDto(
      status: _parseComponentStatus(_requiredString(json, 'status')),
      engine: _requiredString(json, 'engine'),
      latencyMs: _optionalNonNegativeDouble(
        json['latency_ms'],
        fieldName: 'latency_ms',
      ),
      sizeBytes: _optionalNonNegativeInt(
        json['size_bytes'],
        fieldName: 'size_bytes',
      ),
      walSizeBytes: _optionalNonNegativeInt(
        json['wal_size_bytes'],
        fieldName: 'wal_size_bytes',
      ),
      integrityCheck: _parseDatabaseCheckStatus(
        _requiredString(json, 'integrity_check'),
      ),
      foreignKeyCheck: _parseDatabaseCheckStatus(
        _requiredString(json, 'foreign_key_check'),
      ),
      migration: ServerDatabaseMigrationDto.fromJson(
        _requiredMap(json, 'migration'),
      ),
    );
  }

  final ServerComponentStatus status;
  final String engine;

  final double? latencyMs;
  final int? sizeBytes;
  final int? walSizeBytes;

  final ServerDatabaseCheckStatus integrityCheck;
  final ServerDatabaseCheckStatus foreignKeyCheck;

  final ServerDatabaseMigrationDto migration;

  ServerDatabaseHealth toDomain() {
    return ServerDatabaseHealth(
      status: status,
      engine: engine,
      latencyMs: latencyMs,
      sizeBytes: sizeBytes,
      walSizeBytes: walSizeBytes,
      integrityCheck: integrityCheck,
      foreignKeyCheck: foreignKeyCheck,
      migration: migration.toDomain(),
    );
  }
}

final class ServerDatabaseMigrationDto {
  const ServerDatabaseMigrationDto({
    required this.revision,
    required this.message,
  });

  factory ServerDatabaseMigrationDto.fromJson(Map<String, dynamic> json) {
    return ServerDatabaseMigrationDto(
      revision: _optionalString(json['revision'], fieldName: 'revision'),
      message: _optionalString(json['message'], fieldName: 'message'),
    );
  }

  final String? revision;
  final String? message;

  ServerDatabaseMigration toDomain() {
    return ServerDatabaseMigration(revision: revision, message: message);
  }
}

final class ServerTmdbHealthDto {
  const ServerTmdbHealthDto({
    required this.status,
    required this.configured,
    required this.latencyMs,
  });

  factory ServerTmdbHealthDto.fromJson(Map<String, dynamic> json) {
    return ServerTmdbHealthDto(
      status: _parseComponentStatus(_requiredString(json, 'status')),
      configured: _requiredBool(json, 'configured'),
      latencyMs: _optionalNonNegativeDouble(
        json['latency_ms'],
        fieldName: 'latency_ms',
      ),
    );
  }

  final ServerComponentStatus status;
  final bool configured;
  final double? latencyMs;

  ServerTmdbHealth toDomain() {
    return ServerTmdbHealth(
      status: status,
      configured: configured,
      latencyMs: latencyMs,
    );
  }
}

Map<String, dynamic> _requiredMap(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! Map<String, dynamic>) {
    throw FormatException('Invalid $key.');
  }

  return value;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Invalid $key.');
  }

  return value.trim();
}

bool _requiredBool(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! bool) {
    throw FormatException('Invalid $key.');
  }

  return value;
}

int _requiredNonNegativeInt(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! int || value < 0) {
    throw FormatException('Invalid $key.');
  }

  return value;
}

double? _optionalNonNegativeDouble(Object? value, {required String fieldName}) {
  if (value == null) {
    return null;
  }

  if (value is! num || value < 0) {
    throw FormatException('Invalid $fieldName.');
  }

  return value.toDouble();
}

DateTime _requiredDateTime(Map<String, dynamic> json, String key) {
  final String raw = _requiredString(json, key);

  final DateTime? value = DateTime.tryParse(raw);

  if (value == null) {
    throw FormatException('Invalid $key.');
  }

  return value;
}

ServerHealthStatus _parseHealthStatus(String value) {
  return switch (value) {
    'healthy' => ServerHealthStatus.healthy,
    'degraded' => ServerHealthStatus.degraded,
    'unavailable' => ServerHealthStatus.unavailable,
    _ => throw FormatException('Invalid Server health status: $value.'),
  };
}

ServerComponentStatus _parseComponentStatus(String value) {
  return switch (value) {
    'healthy' => ServerComponentStatus.healthy,
    'unavailable' => ServerComponentStatus.unavailable,
    _ => throw FormatException('Invalid Server component status: $value.'),
  };
}

int? _optionalNonNegativeInt(Object? value, {required String fieldName}) {
  if (value == null) {
    return null;
  }

  if (value is! int || value < 0) {
    throw FormatException('Invalid $fieldName.');
  }

  return value;
}

String? _optionalString(Object? value, {required String fieldName}) {
  if (value == null) {
    return null;
  }

  if (value is! String) {
    throw FormatException('Invalid $fieldName.');
  }

  final String trimmed = value.trim();

  return trimmed.isEmpty ? null : trimmed;
}

ServerDatabaseCheckStatus _parseDatabaseCheckStatus(String value) {
  return switch (value) {
    'ok' => ServerDatabaseCheckStatus.ok,
    'failed' => ServerDatabaseCheckStatus.failed,
    'unavailable' => ServerDatabaseCheckStatus.unavailable,
    _ => throw FormatException('Invalid Server database check status: $value.'),
  };
}
