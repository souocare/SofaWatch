import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/statistics/data/repositories/api_statistics_repository.dart';
import 'package:sofawatch/features/statistics/domain/models/weekly_statistics.dart';

void main() {
  group('ApiStatisticsRepository', () {
    late ApiClient apiClient;
    late DioAdapter dioAdapter;
    late ApiStatisticsRepository repository;

    setUp(() {
      apiClient = ApiClient(baseUrl: Uri.parse('http://localhost:8000'));

      dioAdapter = DioAdapter(dio: apiClient.dio, printLogs: false);

      repository = ApiStatisticsRepository(apiClient);
    });

    test('loads weekly Statistics', () async {
      dioAdapter.onGet('/statistics/weekly', (server) {
        server.reply(200, <String, dynamic>{
          'week_start': '2026-08-17',
          'week_end': '2026-08-23',
          'episodes_watched': 8,
          'movies_watched': 2,
          'watch_time_minutes': 642,
        });
      });

      final WeeklyStatistics result = await repository.getWeeklyStatistics();

      expect(result.episodesWatched, 8);
      expect(result.moviesWatched, 2);
      expect(result.watchTimeMinutes, 642);

      expect(result.weekStart, DateTime(2026, 8, 17));

      expect(result.weekEnd, DateTime(2026, 8, 23));
    });

    test('supports a week without viewing activity', () async {
      dioAdapter.onGet('/statistics/weekly', (server) {
        server.reply(200, <String, dynamic>{
          'week_start': '2026-08-17',
          'week_end': '2026-08-23',
          'episodes_watched': 0,
          'movies_watched': 0,
          'watch_time_minutes': 0,
        });
      });

      final WeeklyStatistics result = await repository.getWeeklyStatistics();

      expect(result.episodesWatched, 0);
      expect(result.moviesWatched, 0);
      expect(result.watchTimeMinutes, 0);
    });

    test('maps malformed Statistics response to invalidData', () async {
      dioAdapter.onGet('/statistics/weekly', (server) {
        server.reply(200, <String, dynamic>{
          'week_start': '2026-08-17',
          'week_end': '2026-08-23',
          'episodes_watched': -1,
          'movies_watched': 2,
          'watch_time_minutes': 642,
        });
      });

      expect(
        repository.getWeeklyStatistics(),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('maps missing response body to invalidData', () async {
      dioAdapter.onGet('/statistics/weekly', (server) {
        server.reply(200, null);
      });

      expect(
        repository.getWeeklyStatistics(),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('propagates API errors unchanged', () async {
      dioAdapter.onGet('/statistics/weekly', (server) {
        server.reply(500, <String, dynamic>{
          'error': <String, dynamic>{
            'code': 'internal_error',
            'message': 'Unexpected error.',
          },
        });
      });

      expect(repository.getWeeklyStatistics(), throwsA(isA<AppException>()));
    });
  });
}
