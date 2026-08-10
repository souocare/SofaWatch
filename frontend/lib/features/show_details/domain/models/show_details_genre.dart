import 'package:equatable/equatable.dart';

final class ShowDetailsGenre extends Equatable {
  const ShowDetailsGenre({required this.tmdbId, required this.name});

  final int tmdbId;
  final String name;

  @override
  List<Object?> get props => <Object?>[tmdbId, name];
}
