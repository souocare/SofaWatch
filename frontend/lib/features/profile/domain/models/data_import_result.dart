import 'package:equatable/equatable.dart';

final class DataImportResult extends Equatable {
  const DataImportResult({required this.library, required this.history});

  final DataImportLibraryResult library;
  final DataImportHistoryResult history;

  bool get hasFailures {
    return library.hasFailures || history.hasFailures;
  }

  @override
  List<Object?> get props => <Object?>[library, history];
}

final class DataImportLibraryResult extends Equatable {
  const DataImportLibraryResult({required this.shows, required this.movies});

  final DataImportMediaResult shows;
  final DataImportMediaResult movies;

  bool get hasFailures {
    return shows.hasFailures || movies.hasFailures;
  }

  @override
  List<Object?> get props => <Object?>[shows, movies];
}

final class DataImportMediaResult extends Equatable {
  const DataImportMediaResult({
    required this.created,
    required this.updated,
    required this.unchanged,
    required this.failed,
  });

  final int created;
  final int updated;
  final int unchanged;
  final int failed;

  bool get hasFailures => failed > 0;

  @override
  List<Object?> get props => <Object?>[created, updated, unchanged, failed];
}

final class DataImportHistoryResult extends Equatable {
  const DataImportHistoryResult({required this.episodes, required this.movies});

  final DataImportHistoryMediaResult episodes;
  final DataImportHistoryMediaResult movies;

  bool get hasFailures {
    return episodes.hasFailures || movies.hasFailures;
  }

  @override
  List<Object?> get props => <Object?>[episodes, movies];
}

final class DataImportHistoryMediaResult extends Equatable {
  const DataImportHistoryMediaResult({
    required this.created,
    required this.skipped,
    required this.failed,
  });

  final int created;
  final int skipped;
  final int failed;

  bool get hasFailures => failed > 0;

  @override
  List<Object?> get props => <Object?>[created, skipped, failed];
}
