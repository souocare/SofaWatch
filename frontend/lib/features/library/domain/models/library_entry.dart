import 'package:equatable/equatable.dart';
import 'package:sofawatch/features/library/domain/models/library_media_type.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';

final class LibraryEntry extends Equatable {
  const LibraryEntry({
    required this.id,
    required this.mediaId,
    required this.mediaType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.rating,
    this.startedAt,
    this.completedAt,
  });

  final String id;

  /// Internal SofaWatch Show/Movie UUID.
  final String mediaId;

  final LibraryMediaType mediaType;

  final LibraryStatus status;

  final double? rating;

  final DateTime? startedAt;
  final DateTime? completedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => <Object?>[
    id,
    mediaId,
    mediaType,
    status,
    rating,
    startedAt,
    completedAt,
    createdAt,
    updatedAt,
  ];
}
