import 'package:equatable/equatable.dart';

abstract class HistoryItem extends Equatable {
  const HistoryItem({required this.eventId, required this.watchedAt});

  final String eventId;
  final DateTime watchedAt;
}
