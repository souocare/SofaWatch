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

final class ServerEnvironment extends Equatable {
  const ServerEnvironment({
    required this.appName,
    required this.environment,
    required this.debug,
    required this.apiHost,
    required this.apiPort,
    required this.defaultLanguage,
    required this.supportedLanguages,
    required this.metadataRefreshDays,
  });

  final String appName;
  final String environment;
  final bool debug;
  final String apiHost;
  final int apiPort;
  final String defaultLanguage;
  final List<String> supportedLanguages;
  final int metadataRefreshDays;

  @override
  List<Object?> get props => <Object?>[
    appName,
    environment,
    debug,
    apiHost,
    apiPort,
    defaultLanguage,
    supportedLanguages,
    metadataRefreshDays,
  ];
}

final class ServerImageCacheCategory extends Equatable {
  const ServerImageCacheCategory({
    required this.sizeBytes,
    required this.files,
  });

  final int sizeBytes;
  final int files;

  @override
  List<Object?> get props => <Object?>[sizeBytes, files];
}

final class ServerImageCacheBreakdown extends Equatable {
  const ServerImageCacheBreakdown({
    required this.shows,
    required this.seasons,
    required this.episodes,
  });

  final ServerImageCacheCategory shows;
  final ServerImageCacheCategory seasons;
  final ServerImageCacheCategory episodes;

  @override
  List<Object?> get props => <Object?>[shows, seasons, episodes];
}

final class ServerImageCache extends Equatable {
  const ServerImageCache({
    required this.totalSizeBytes,
    required this.totalFiles,
    required this.breakdown,
  });

  final int totalSizeBytes;
  final int totalFiles;
  final ServerImageCacheBreakdown breakdown;

  @override
  List<Object?> get props => <Object?>[totalSizeBytes, totalFiles, breakdown];
}

final class ServerStorage extends Equatable {
  const ServerStorage({
    required this.dataDirectory,
    required this.writable,
    required this.imageCache,
    this.totalSpaceBytes,
    this.usedSpaceBytes,
    this.freeSpaceBytes,
    this.usagePercentage,
  });

  final String dataDirectory;
  final bool writable;

  final int? totalSpaceBytes;
  final int? usedSpaceBytes;
  final int? freeSpaceBytes;
  final double? usagePercentage;

  final ServerImageCache imageCache;

  @override
  List<Object?> get props => <Object?>[
    dataDirectory,
    writable,
    totalSpaceBytes,
    usedSpaceBytes,
    freeSpaceBytes,
    usagePercentage,
    imageCache,
  ];
}

final class ServerRuntime extends Equatable {
  const ServerRuntime({
    required this.pythonVersion,
    required this.platform,
    required this.startedAt,
  });

  final String pythonVersion;
  final String platform;
  final DateTime startedAt;

  @override
  List<Object?> get props => <Object?>[pythonVersion, platform, startedAt];
}

final class ServerHealth extends Equatable {
  const ServerHealth({
    required this.status,
    required this.checkedAt,
    required this.uptimeSeconds,
    required this.environment,
    required this.storage,
    required this.runtime,
    required this.database,
    required this.tmdb,
  });

  final ServerHealthStatus status;
  final DateTime checkedAt;
  final int uptimeSeconds;

  final ServerEnvironment environment;
  final ServerStorage storage;
  final ServerRuntime runtime;

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
    environment,
    storage,
    runtime,
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
