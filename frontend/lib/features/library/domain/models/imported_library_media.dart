import 'package:equatable/equatable.dart';
import 'package:sofawatch/features/library/domain/models/library_media_type.dart';

final class ImportedLibraryMedia extends Equatable {
  const ImportedLibraryMedia({
    required this.id,
    required this.tmdbId,
    required this.mediaType,
  });

  final String id;
  final int tmdbId;
  final LibraryMediaType mediaType;

  @override
  List<Object?> get props => <Object?>[id, tmdbId, mediaType];
}
