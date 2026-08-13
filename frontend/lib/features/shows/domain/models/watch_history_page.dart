import 'package:equatable/equatable.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_item.dart';

final class WatchHistoryPage extends Equatable {
  const WatchHistoryPage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final List<WatchHistoryItem> items;
  final String? nextCursor;
  final bool hasMore;

  @override
  List<Object?> get props => <Object?>[items, nextCursor, hasMore];
}
