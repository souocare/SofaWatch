import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/episode_progress/data/repositories/api_episode_progress_repository.dart';

void main() {
  group('ApiEpisodeProgressRepository', () {
    late ApiClient apiClient;
    late DioAdapter dioAdapter;
    late ApiEpisodeProgressRepository repository;

    setUp(() {
      apiClient = ApiClient(baseUrl: Uri.parse('http://localhost:8000'));

      dioAdapter = DioAdapter(dio: apiClient.dio, printLogs: false);

      repository = ApiEpisodeProgressRepository(apiClient);
    });

    test('marks an Episode as watched', () async {
      dioAdapter.onPost(
        '/episodes/episode-1/watched',
        data: <String, dynamic>{'watched_at': null},
        (server) {
          server.reply(200, <String, dynamic>{
            'episode_id': 'episode-1',
            'is_watched': true,
            'watched_at': '2026-08-13T00:30:00Z',
          });
        },
      );

      await expectLater(
        repository.markEpisodeWatched(episodeId: 'episode-1'),
        completes,
      );
    });

    test('sends an explicit watched timestamp in UTC', () async {
      final DateTime watchedAt = DateTime.parse('2026-08-13T01:30:00+01:00');

      dioAdapter.onPost(
        '/episodes/episode-1/watched',
        data: <String, dynamic>{'watched_at': '2026-08-13T00:30:00.000Z'},
        (server) {
          server.reply(200, <String, dynamic>{
            'episode_id': 'episode-1',
            'is_watched': true,
            'watched_at': '2026-08-13T00:30:00Z',
          });
        },
      );

      await expectLater(
        repository.markEpisodeWatched(
          episodeId: 'episode-1',
          watchedAt: watchedAt,
        ),
        completes,
      );
    });

    test('propagates API errors', () async {
      dioAdapter.onPost(
        '/episodes/episode-1/watched',
        data: <String, dynamic>{'watched_at': null},
        (server) {
          server.reply(500, <String, dynamic>{
            'code': 'server_error',
            'message': 'Something went wrong.',
          });
        },
      );

      expect(
        repository.markEpisodeWatched(episodeId: 'episode-1'),
        throwsA(isA<AppException>()),
      );
    });
  });
}
