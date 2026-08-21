import 'package:sofawatch/features/profile/domain/models/data_import_result.dart';

final class DataImportResultDto {
  const DataImportResultDto({required this.library, required this.history});

  factory DataImportResultDto.fromJson(Map<String, dynamic> json) {
    return DataImportResultDto(
      library: DataImportLibraryResultDto.fromJson(
        json['library'] as Map<String, dynamic>,
      ),
      history: DataImportHistoryResultDto.fromJson(
        json['history'] as Map<String, dynamic>,
      ),
    );
  }

  final DataImportLibraryResultDto library;
  final DataImportHistoryResultDto history;

  DataImportResult toDomain() {
    return DataImportResult(
      library: library.toDomain(),
      history: history.toDomain(),
    );
  }
}

final class DataImportLibraryResultDto {
  const DataImportLibraryResultDto({required this.shows, required this.movies});

  factory DataImportLibraryResultDto.fromJson(Map<String, dynamic> json) {
    return DataImportLibraryResultDto(
      shows: DataImportMediaResultDto.fromJson(
        json['shows'] as Map<String, dynamic>,
      ),
      movies: DataImportMediaResultDto.fromJson(
        json['movies'] as Map<String, dynamic>,
      ),
    );
  }

  final DataImportMediaResultDto shows;
  final DataImportMediaResultDto movies;

  DataImportLibraryResult toDomain() {
    return DataImportLibraryResult(
      shows: shows.toDomain(),
      movies: movies.toDomain(),
    );
  }
}

final class DataImportMediaResultDto {
  const DataImportMediaResultDto({
    required this.created,
    required this.updated,
    required this.unchanged,
    required this.failed,
  });

  factory DataImportMediaResultDto.fromJson(Map<String, dynamic> json) {
    return DataImportMediaResultDto(
      created: json['created'] as int,
      updated: json['updated'] as int,
      unchanged: json['unchanged'] as int,
      failed: json['failed'] as int,
    );
  }

  final int created;
  final int updated;
  final int unchanged;
  final int failed;

  DataImportMediaResult toDomain() {
    return DataImportMediaResult(
      created: created,
      updated: updated,
      unchanged: unchanged,
      failed: failed,
    );
  }
}

final class DataImportHistoryResultDto {
  const DataImportHistoryResultDto({
    required this.episodes,
    required this.movies,
  });

  factory DataImportHistoryResultDto.fromJson(Map<String, dynamic> json) {
    return DataImportHistoryResultDto(
      episodes: DataImportHistoryMediaResultDto.fromJson(
        json['episodes'] as Map<String, dynamic>,
      ),
      movies: DataImportHistoryMediaResultDto.fromJson(
        json['movies'] as Map<String, dynamic>,
      ),
    );
  }

  final DataImportHistoryMediaResultDto episodes;
  final DataImportHistoryMediaResultDto movies;

  DataImportHistoryResult toDomain() {
    return DataImportHistoryResult(
      episodes: episodes.toDomain(),
      movies: movies.toDomain(),
    );
  }
}

final class DataImportHistoryMediaResultDto {
  const DataImportHistoryMediaResultDto({
    required this.created,
    required this.skipped,
    required this.failed,
  });

  factory DataImportHistoryMediaResultDto.fromJson(Map<String, dynamic> json) {
    return DataImportHistoryMediaResultDto(
      created: json['created'] as int,
      skipped: json['skipped'] as int,
      failed: json['failed'] as int,
    );
  }

  final int created;
  final int skipped;
  final int failed;

  DataImportHistoryMediaResult toDomain() {
    return DataImportHistoryMediaResult(
      created: created,
      skipped: skipped,
      failed: failed,
    );
  }
}
