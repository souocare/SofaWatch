import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/history/domain/models/history_preview.dart';

sealed class HistoryPreviewState extends Equatable {
  const HistoryPreviewState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class HistoryPreviewInitial extends HistoryPreviewState {
  const HistoryPreviewInitial();
}

final class HistoryPreviewLoading extends HistoryPreviewState {
  const HistoryPreviewLoading();
}

final class HistoryPreviewSuccess extends HistoryPreviewState {
  const HistoryPreviewSuccess(this.preview);

  final HistoryPreview preview;

  @override
  List<Object?> get props => <Object?>[preview];
}

final class HistoryPreviewFailure extends HistoryPreviewState {
  const HistoryPreviewFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => <Object?>[error];
}
