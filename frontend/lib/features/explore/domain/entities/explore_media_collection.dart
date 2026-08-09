import 'package:sofawatch/features/explore/domain/entities/explore_media_item.dart';

class ExploreMediaCollection {
  const ExploreMediaCollection({required this.items});

  final List<ExploreMediaItem> items;

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;
}
