import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';

sealed class ShowsState extends Equatable {
  const ShowsState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class ShowsInitial extends ShowsState {
  const ShowsInitial();
}

final class ShowsLoading extends ShowsState {
  const ShowsLoading();
}

final class ShowsSuccess extends ShowsState {
  const ShowsSuccess(this.shows);

  final List<LibraryShow> shows;

  bool get isEmpty => shows.isEmpty;

  @override
  List<Object?> get props => <Object?>[shows];
}

final class ShowsFailure extends ShowsState {
  const ShowsFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => <Object?>[error];
}
