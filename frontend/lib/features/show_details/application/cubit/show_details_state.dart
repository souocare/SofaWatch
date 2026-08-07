import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details.dart';

sealed class ShowDetailsState extends Equatable {
  const ShowDetailsState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class ShowDetailsInitial extends ShowDetailsState {
  const ShowDetailsInitial();
}

final class ShowDetailsLoading extends ShowDetailsState {
  const ShowDetailsLoading();
}

final class ShowDetailsSuccess extends ShowDetailsState {
  const ShowDetailsSuccess(this.details);

  final ShowDetails details;

  @override
  List<Object?> get props => <Object?>[details];
}

final class ShowDetailsFailure extends ShowDetailsState {
  const ShowDetailsFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => <Object?>[error];
}
