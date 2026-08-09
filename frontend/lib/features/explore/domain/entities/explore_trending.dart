import 'package:equatable/equatable.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_item.dart';

class ExploreTrending extends Equatable {
  ExploreTrending({required List<ExploreMediaItem> items})
    : items = List<ExploreMediaItem>.unmodifiable(items);

  final List<ExploreMediaItem> items;

  List<ExploreMediaItem> get shows => List<ExploreMediaItem>.unmodifiable(
    items.where(
      (ExploreMediaItem item) => item.mediaType == ExploreMediaType.show,
    ),
  );

  List<ExploreMediaItem> get movies => List<ExploreMediaItem>.unmodifiable(
    items.where(
      (ExploreMediaItem item) => item.mediaType == ExploreMediaType.movie,
    ),
  );

  bool get isEmpty => items.isEmpty;

  @override
  List<Object?> get props => <Object?>[items];
}
