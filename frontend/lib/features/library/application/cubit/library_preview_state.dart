import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/domain/models/library_preview.dart';

sealed class LibraryPreviewState extends Equatable {
  const LibraryPreviewState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class LibraryPreviewInitial extends LibraryPreviewState {
  const LibraryPreviewInitial();
}

final class LibraryPreviewLoading extends LibraryPreviewState {
  const LibraryPreviewLoading();
}

final class LibraryPreviewSuccess extends LibraryPreviewState {
  const LibraryPreviewSuccess(this.preview);

  final LibraryPreview preview;

  @override
  List<Object?> get props => <Object?>[preview];
}

final class LibraryPreviewFailure extends LibraryPreviewState {
  const LibraryPreviewFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => <Object?>[error];
}
