import 'package:equatable/equatable.dart';

enum ServerLogLevel { debug, info, warning, error, critical }

enum ServerLogComponent { api, worker }

final class ServerLogEntry extends Equatable {
  const ServerLogEntry({
    required this.timestamp,
    required this.level,
    required this.logger,
    required this.message,
    required this.component,
  });

  final DateTime timestamp;
  final ServerLogLevel level;
  final String logger;
  final String message;
  final ServerLogComponent component;

  @override
  List<Object?> get props => <Object?>[
    timestamp,
    level,
    logger,
    message,
    component,
  ];
}

final class ServerLogsPage extends Equatable {
  const ServerLogsPage({
    required this.items,
    required this.offset,
    required this.limit,
    required this.total,
    required this.hasNext,
  });

  final List<ServerLogEntry> items;

  final int offset;
  final int limit;
  final int total;
  final bool hasNext;

  @override
  List<Object?> get props => <Object?>[items, offset, limit, total, hasNext];
}
