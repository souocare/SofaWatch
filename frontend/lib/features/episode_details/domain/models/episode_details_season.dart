import 'package:equatable/equatable.dart';

final class EpisodeDetailsSeason extends Equatable {
  const EpisodeDetailsSeason({
    required this.id,
    required this.seasonNumber,
    required this.title,
  });

  final String id;
  final int seasonNumber;
  final String title;

  @override
  List<Object?> get props => <Object?>[id, seasonNumber, title];
}
