import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/domain/models/library_entry.dart';

enum LibraryItemOperationStatus { idle, adding, added, failure }

final class LibraryItemOperation extends Equatable {
  const LibraryItemOperation._({required this.status, this.entry, this.error});

  const LibraryItemOperation.idle()
    : this._(status: LibraryItemOperationStatus.idle);

  const LibraryItemOperation.adding()
    : this._(status: LibraryItemOperationStatus.adding);

  const LibraryItemOperation.added({LibraryEntry? entry})
    : this._(status: LibraryItemOperationStatus.added, entry: entry);

  const LibraryItemOperation.failure(AppException error)
    : this._(status: LibraryItemOperationStatus.failure, error: error);

  final LibraryItemOperationStatus status;

  final LibraryEntry? entry;
  final AppException? error;

  bool get isAdding {
    return status == LibraryItemOperationStatus.adding;
  }

  bool get isAdded {
    return status == LibraryItemOperationStatus.added;
  }

  bool get hasFailed {
    return status == LibraryItemOperationStatus.failure;
  }

  @override
  List<Object?> get props => <Object?>[status, entry, error];
}
