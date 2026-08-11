import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/domain/models/library_entry.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';

enum LibraryItemOperationStatus {
  idle,
  adding,
  added,
  removing,
  updating,
  failure,
}

final class LibraryItemOperation extends Equatable {
  const LibraryItemOperation._({
    required this.status,
    this.entry,
    this.error,
    this.targetStatus,
  });

  const LibraryItemOperation.idle()
    : this._(status: LibraryItemOperationStatus.idle);

  const LibraryItemOperation.adding()
    : this._(status: LibraryItemOperationStatus.adding);

  const LibraryItemOperation.added({LibraryEntry? entry})
    : this._(status: LibraryItemOperationStatus.added, entry: entry);

  const LibraryItemOperation.removing({required LibraryEntry entry})
    : this._(status: LibraryItemOperationStatus.removing, entry: entry);

  const LibraryItemOperation.updating({
    required LibraryEntry entry,
    required LibraryStatus targetStatus,
  }) : this._(
         status: LibraryItemOperationStatus.updating,
         entry: entry,
         targetStatus: targetStatus,
       );

  const LibraryItemOperation.failure(
    AppException error, {
    LibraryEntry? entry,
    LibraryStatus? targetStatus,
  }) : this._(
         status: LibraryItemOperationStatus.failure,
         error: error,
         entry: entry,
         targetStatus: targetStatus,
       );

  final LibraryItemOperationStatus status;

  final LibraryEntry? entry;
  final AppException? error;

  /// Desired Library status when a status update is in progress or failed.
  final LibraryStatus? targetStatus;

  bool get isAdding => status == LibraryItemOperationStatus.adding;

  bool get isAdded => status == LibraryItemOperationStatus.added;

  bool get isRemoving => status == LibraryItemOperationStatus.removing;

  bool get isUpdating => status == LibraryItemOperationStatus.updating;

  bool get hasFailed => status == LibraryItemOperationStatus.failure;

  bool get isStatusUpdateFailure {
    return hasFailed && entry != null && targetStatus != null;
  }

  @override
  List<Object?> get props => <Object?>[status, entry, error, targetStatus];
}
