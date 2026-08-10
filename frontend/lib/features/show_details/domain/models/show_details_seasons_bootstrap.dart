import 'package:equatable/equatable.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_local_season.dart';

final class ShowDetailsSeasonsBootstrap extends Equatable {
  const ShowDetailsSeasonsBootstrap({
    required this.showId,
    required this.seasons,
  });

  final String showId;
  final List<ShowDetailsLocalSeason> seasons;

  @override
  List<Object?> get props => <Object?>[showId, seasons];
}
