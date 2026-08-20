import 'package:sofawatch/features/server/domain/models/server_health.dart';

final class ServerHealthDto {
  const ServerHealthDto({
    required this.status,
    required this.checkedAt,
    required this.uptimeSeconds,
    required this.environment,
    required this.storage,
    required this.runtime,
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
      environment: ServerEnvironmentDto.fromJson(
        _requiredMap(json, 'environment'),
      ),
      storage: ServerStorageDto.fromJson(_requiredMap(json, 'storage')),
      runtime: ServerRuntimeDto.fromJson(_requiredMap(json, 'runtime')),
    );
  }

  final ServerHealthStatus status;
  final DateTime checkedAt;
  final int uptimeSeconds;

  final ServerDatabaseHealthDto database;
  final ServerTmdbHealthDto tmdb;

  final ServerEnvironmentDto environment;
  final ServerStorageDto storage;
  final ServerRuntimeDto runtime;

  ServerHealth toDomain() {
    return ServerHealth(
      status: status,
      checkedAt: checkedAt,
      uptimeSeconds: uptimeSeconds,
      database: database.toDomain(),
      tmdb: tmdb.toDomain(),
      environment: environment.toDomain(),
      storage: storage.toDomain(),
      runtime: runtime.toDomain(),
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

final class ServerEnvironmentDto {
  const ServerEnvironmentDto({
    required this.appName,
    required this.environment,
    required this.debug,
    required this.apiHost,
    required this.apiPort,
    required this.defaultLanguage,
    required this.supportedLanguages,
    required this.metadataRefreshDays,
  });

  factory ServerEnvironmentDto.fromJson(Map<String, dynamic> json) {
    return ServerEnvironmentDto(
      appName: _requiredString(json, 'app_name'),
      environment: _requiredString(json, 'environment'),
      debug: _requiredBool(json, 'debug'),
      apiHost: _requiredString(json, 'api_host'),
      apiPort: _requiredPositiveInt(json, 'api_port'),
      defaultLanguage: _requiredString(json, 'default_language'),
      supportedLanguages: _requiredStringList(json, 'supported_languages'),
      metadataRefreshDays: _requiredPositiveInt(json, 'metadata_refresh_days'),
    );
  }

  final String appName;
  final String environment;
  final bool debug;
  final String apiHost;
  final int apiPort;
  final String defaultLanguage;
  final List<String> supportedLanguages;
  final int metadataRefreshDays;

  ServerEnvironment toDomain() {
    return ServerEnvironment(
      appName: appName,
      environment: environment,
      debug: debug,
      apiHost: apiHost,
      apiPort: apiPort,
      defaultLanguage: defaultLanguage,
      supportedLanguages: supportedLanguages,
      metadataRefreshDays: metadataRefreshDays,
    );
  }
}

final class ServerImageCacheCategoryDto {
  const ServerImageCacheCategoryDto({
    required this.sizeBytes,
    required this.files,
  });

  factory ServerImageCacheCategoryDto.fromJson(Map<String, dynamic> json) {
    return ServerImageCacheCategoryDto(
      sizeBytes: _requiredNonNegativeInt(json, 'size_bytes'),
      files: _requiredNonNegativeInt(json, 'files'),
    );
  }

  final int sizeBytes;
  final int files;

  ServerImageCacheCategory toDomain() {
    return ServerImageCacheCategory(sizeBytes: sizeBytes, files: files);
  }
}

final class ServerImageCacheBreakdownDto {
  const ServerImageCacheBreakdownDto({
    required this.shows,
    required this.seasons,
    required this.episodes,
  });

  factory ServerImageCacheBreakdownDto.fromJson(Map<String, dynamic> json) {
    return ServerImageCacheBreakdownDto(
      shows: ServerImageCacheCategoryDto.fromJson(_requiredMap(json, 'shows')),
      seasons: ServerImageCacheCategoryDto.fromJson(
        _requiredMap(json, 'seasons'),
      ),
      episodes: ServerImageCacheCategoryDto.fromJson(
        _requiredMap(json, 'episodes'),
      ),
    );
  }

  final ServerImageCacheCategoryDto shows;
  final ServerImageCacheCategoryDto seasons;
  final ServerImageCacheCategoryDto episodes;

  ServerImageCacheBreakdown toDomain() {
    return ServerImageCacheBreakdown(
      shows: shows.toDomain(),
      seasons: seasons.toDomain(),
      episodes: episodes.toDomain(),
    );
  }
}

final class ServerImageCacheDto {
  const ServerImageCacheDto({
    required this.totalSizeBytes,
    required this.totalFiles,
    required this.breakdown,
  });

  factory ServerImageCacheDto.fromJson(Map<String, dynamic> json) {
    return ServerImageCacheDto(
      totalSizeBytes: _requiredNonNegativeInt(json, 'total_size_bytes'),
      totalFiles: _requiredNonNegativeInt(json, 'total_files'),
      breakdown: ServerImageCacheBreakdownDto.fromJson(
        _requiredMap(json, 'breakdown'),
      ),
    );
  }

  final int totalSizeBytes;
  final int totalFiles;
  final ServerImageCacheBreakdownDto breakdown;

  ServerImageCache toDomain() {
    return ServerImageCache(
      totalSizeBytes: totalSizeBytes,
      totalFiles: totalFiles,
      breakdown: breakdown.toDomain(),
    );
  }
}

final class ServerStorageDto {
  const ServerStorageDto({
    required this.dataDirectory,
    required this.writable,
    required this.totalSpaceBytes,
    required this.usedSpaceBytes,
    required this.freeSpaceBytes,
    required this.usagePercentage,
    required this.imageCache,
  });

  factory ServerStorageDto.fromJson(Map<String, dynamic> json) {
    return ServerStorageDto(
      dataDirectory: _requiredString(json, 'data_directory'),
      writable: _requiredBool(json, 'writable'),
      totalSpaceBytes: _optionalNonNegativeInt(
        json['total_space_bytes'],
        fieldName: 'total_space_bytes',
      ),
      usedSpaceBytes: _optionalNonNegativeInt(
        json['used_space_bytes'],
        fieldName: 'used_space_bytes',
      ),
      freeSpaceBytes: _optionalNonNegativeInt(
        json['free_space_bytes'],
        fieldName: 'free_space_bytes',
      ),
      usagePercentage: _optionalPercentage(
        json['usage_percentage'],
        fieldName: 'usage_percentage',
      ),
      imageCache: ServerImageCacheDto.fromJson(
        _requiredMap(json, 'image_cache'),
      ),
    );
  }

  final String dataDirectory;
  final bool writable;

  final int? totalSpaceBytes;
  final int? usedSpaceBytes;
  final int? freeSpaceBytes;
  final double? usagePercentage;

  final ServerImageCacheDto imageCache;

  ServerStorage toDomain() {
    return ServerStorage(
      dataDirectory: dataDirectory,
      writable: writable,
      totalSpaceBytes: totalSpaceBytes,
      usedSpaceBytes: usedSpaceBytes,
      freeSpaceBytes: freeSpaceBytes,
      usagePercentage: usagePercentage,
      imageCache: imageCache.toDomain(),
    );
  }
}

final class ServerRuntimeDto {
  const ServerRuntimeDto({
    required this.pythonVersion,
    required this.platform,
    required this.startedAt,
  });

  factory ServerRuntimeDto.fromJson(Map<String, dynamic> json) {
    return ServerRuntimeDto(
      pythonVersion: _requiredString(json, 'python_version'),
      platform: _requiredString(json, 'platform'),
      startedAt: _requiredDateTime(json, 'started_at'),
    );
  }

  final String pythonVersion;
  final String platform;
  final DateTime startedAt;

  ServerRuntime toDomain() {
    return ServerRuntime(
      pythonVersion: pythonVersion,
      platform: platform,
      startedAt: startedAt,
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

int _requiredPositiveInt(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! int || value <= 0) {
    throw FormatException('Invalid $key.');
  }

  return value;
}

List<String> _requiredStringList(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! List) {
    throw FormatException('Invalid $key.');
  }

  final List<String> result = <String>[];

  for (final Object? item in value) {
    if (item is! String || item.trim().isEmpty) {
      throw FormatException('Invalid $key.');
    }

    result.add(item.trim());
  }

  return List<String>.unmodifiable(result);
}

double? _optionalPercentage(Object? value, {required String fieldName}) {
  if (value == null) {
    return null;
  }

  if (value is! num || value < 0 || value > 100) {
    throw FormatException('Invalid $fieldName.');
  }

  return value.toDouble();
}
