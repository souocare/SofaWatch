import 'package:equatable/equatable.dart';
import 'package:sofawatch/features/library/domain/models/library_media_type.dart';

final class LibraryMediaKey extends Equatable {
  const LibraryMediaKey({required this.mediaType, required this.tmdbId});

  final LibraryMediaType mediaType;
  final int tmdbId;

  @override
  List<Object?> get props => <Object?>[mediaType, tmdbId];
}
