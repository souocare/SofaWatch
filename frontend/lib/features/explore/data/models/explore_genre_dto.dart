import 'package:sofawatch/features/explore/domain/entities/explore_genre.dart';

final class ExploreGenreDto {
  const ExploreGenreDto({required this.id, required this.name});

  factory ExploreGenreDto.fromJson(Map<String, dynamic> json) {
    final Object? rawId = json['id'];
    final Object? rawName = json['name'];

    if (rawId is! int || rawId <= 0) {
      throw const FormatException('Invalid Explore genre id.');
    }

    if (rawName is! String || rawName.trim().isEmpty) {
      throw const FormatException('Invalid Explore genre name.');
    }

    return ExploreGenreDto(id: rawId, name: rawName.trim());
  }

  final int id;
  final String name;

  ExploreGenre toDomain() {
    return ExploreGenre(id: id, name: name);
  }
}
