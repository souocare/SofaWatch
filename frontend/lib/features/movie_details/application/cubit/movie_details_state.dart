import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/movie_details/domain/models/movie_details.dart';

sealed class MovieDetailsState extends Equatable {
  const MovieDetailsState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class MovieDetailsInitial extends MovieDetailsState {
  const MovieDetailsInitial();
}

final class MovieDetailsLoading extends MovieDetailsState {
  const MovieDetailsLoading();
}

final class MovieDetailsSuccess extends MovieDetailsState {
  const MovieDetailsSuccess(this.details);

  final MovieDetails details;

  @override
  List<Object?> get props => <Object?>[details];
}

final class MovieDetailsFailure extends MovieDetailsState {
  const MovieDetailsFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => <Object?>[error];
}
