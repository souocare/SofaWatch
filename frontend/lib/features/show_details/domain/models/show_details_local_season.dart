import 'package:equatable/equatable.dart';

final class ShowDetailsLocalSeason extends Equatable {
  const ShowDetailsLocalSeason({
    required this.id,
    required this.tmdbId,
    required this.seasonNumber,
  });

  final String id;
  final int tmdbId;
  final int seasonNumber;

  @override
  List<Object?> get props => <Object?>[id, tmdbId, seasonNumber];
}
