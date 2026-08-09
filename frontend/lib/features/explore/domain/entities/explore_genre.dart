import 'package:equatable/equatable.dart';

final class ExploreGenre extends Equatable {
  const ExploreGenre({required this.id, required this.name});

  final int id;
  final String name;

  @override
  List<Object?> get props => <Object?>[id, name];
}
