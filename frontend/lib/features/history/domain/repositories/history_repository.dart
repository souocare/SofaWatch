import 'package:sofawatch/features/history/domain/models/history_media_type.dart';
import 'package:sofawatch/features/history/domain/models/history_page.dart';
import 'package:sofawatch/features/history/domain/models/history_preview.dart';

abstract interface class HistoryRepository {
  Future<HistoryPreview> getPreview();

  Future<HistoryPage> getHistory({
    int limit = 30,
    String? cursor,
    HistoryMediaType mediaType = HistoryMediaType.all,
  });
}
