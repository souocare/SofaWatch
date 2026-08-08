import 'package:equatable/equatable.dart';
import 'package:sofawatch/features/library/application/cubit/library_item_operation.dart';
import 'package:sofawatch/features/library/domain/models/library_media_key.dart';

final class LibraryState extends Equatable {
  const LibraryState({
    this.operations = const <LibraryMediaKey, LibraryItemOperation>{},
  });

  final Map<LibraryMediaKey, LibraryItemOperation> operations;

  LibraryItemOperation operationFor(LibraryMediaKey key) {
    return operations[key] ?? const LibraryItemOperation.idle();
  }

  LibraryState withOperation(
    LibraryMediaKey key,
    LibraryItemOperation operation,
  ) {
    return LibraryState(
      operations: Map<LibraryMediaKey, LibraryItemOperation>.unmodifiable(
        <LibraryMediaKey, LibraryItemOperation>{...operations, key: operation},
      ),
    );
  }

  @override
  List<Object?> get props => <Object?>[operations];
}
