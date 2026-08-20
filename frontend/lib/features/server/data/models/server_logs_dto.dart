import 'package:sofawatch/features/server/domain/models/server_logs.dart';

final class ServerLogEntryDto {
  const ServerLogEntryDto({
    required this.timestamp,
    required this.level,
    required this.logger,
    required this.message,
    required this.component,
  });

  factory ServerLogEntryDto.fromJson(Map<String, dynamic> json) {
    return ServerLogEntryDto(
      timestamp: _requiredDateTime(json, 'timestamp'),
      level: _parseServerLogLevel(_requiredString(json, 'level')),
      logger: _requiredString(json, 'logger'),
      message: _requiredString(json, 'message', allowEmpty: true),
      component: _parseServerLogComponent(_requiredString(json, 'component')),
    );
  }

  final DateTime timestamp;
  final ServerLogLevel level;
  final String logger;
  final String message;
  final ServerLogComponent component;

  ServerLogEntry toDomain() {
    return ServerLogEntry(
      timestamp: timestamp,
      level: level,
      logger: logger,
      message: message,
      component: component,
    );
  }
}

final class ServerLogsPageDto {
  const ServerLogsPageDto({
    required this.items,
    required this.offset,
    required this.limit,
    required this.total,
    required this.hasNext,
  });

  factory ServerLogsPageDto.fromJson(Map<String, dynamic> json) {
    final Object? rawItems = json['items'];

    if (rawItems is! List<dynamic>) {
      throw const FormatException('Invalid items.');
    }

    final List<ServerLogEntryDto> items = rawItems
        .map((dynamic item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('Invalid Server log entry.');
          }

          return ServerLogEntryDto.fromJson(item);
        })
        .toList(growable: false);

    return ServerLogsPageDto(
      items: items,
      offset: _requiredNonNegativeInt(json, 'offset'),
      limit: _requiredPositiveInt(json, 'limit'),
      total: _requiredNonNegativeInt(json, 'total'),
      hasNext: _requiredBool(json, 'has_next'),
    );
  }

  final List<ServerLogEntryDto> items;

  final int offset;
  final int limit;
  final int total;
  final bool hasNext;

  ServerLogsPage toDomain() {
    return ServerLogsPage(
      items: items
          .map((ServerLogEntryDto item) => item.toDomain())
          .toList(growable: false),
      offset: offset,
      limit: limit,
      total: total,
      hasNext: hasNext,
    );
  }
}

String _requiredString(
  Map<String, dynamic> json,
  String key, {
  bool allowEmpty = false,
}) {
  final Object? value = json[key];

  if (value is! String) {
    throw FormatException('Invalid $key.');
  }

  final String normalized = value.trim();

  if (!allowEmpty && normalized.isEmpty) {
    throw FormatException('Invalid $key.');
  }

  return normalized;
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

int _requiredPositiveInt(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! int || value <= 0) {
    throw FormatException('Invalid $key.');
  }

  return value;
}

DateTime _requiredDateTime(Map<String, dynamic> json, String key) {
  final String value = _requiredString(json, key);

  final DateTime? parsed = DateTime.tryParse(value);

  if (parsed == null) {
    throw FormatException('Invalid $key.');
  }

  return parsed;
}

ServerLogLevel _parseServerLogLevel(String value) {
  return switch (value) {
    'DEBUG' => ServerLogLevel.debug,
    'INFO' => ServerLogLevel.info,
    'WARNING' => ServerLogLevel.warning,
    'ERROR' => ServerLogLevel.error,
    'CRITICAL' => ServerLogLevel.critical,
    _ => throw FormatException('Invalid Server log level: $value.'),
  };
}

ServerLogComponent _parseServerLogComponent(String value) {
  return switch (value) {
    'api' => ServerLogComponent.api,
    'worker' => ServerLogComponent.worker,
    _ => throw FormatException('Invalid Server log component: $value.'),
  };
}
