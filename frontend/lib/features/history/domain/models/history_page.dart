import 'package:equatable/equatable.dart';
import 'package:sofawatch/features/history/domain/models/history_item.dart';

final class HistoryPage extends Equatable {
  const HistoryPage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final List<HistoryItem> items;
  final String? nextCursor;
  final bool hasMore;

  @override
  List<Object?> get props => <Object?>[items, nextCursor, hasMore];
}
