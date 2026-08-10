import 'package:dio/dio.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_episode.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_local_season.dart';
import 'package:sofawatch/features/show_details/domain/repositories/show_details_seasons_repository.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_season_progress.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_seasons_bootstrap.dart';

final class ApiShowDetailsSeasonsRepository
    implements ShowDetailsSeasonsRepository {
  ApiShowDetailsSeasonsRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<ShowDetailsSeasonsBootstrap> resolveLocalSeasons({
    required int showTmdbId,
  }) async {
    try {
      final Response<dynamic> importResponse = await _apiClient.post<dynamic>(
        '/shows/import/tmdb/$showTmdbId',
      );

      final Object? importedShow = importResponse.data;

      if (importedShow is! Map<String, dynamic>) {
        throw const FormatException('Invalid imported Show response.');
      }

      final Object? rawShowId = importedShow['id'];

      if (rawShowId is! String || rawShowId.isEmpty) {
        throw const FormatException(
          'Imported Show does not contain a valid local ID.',
        );
      }

      final Response<dynamic> seasonsResponse = await _apiClient.get<dynamic>(
        '/shows/$rawShowId/seasons',
      );

      final Object? response = seasonsResponse.data;

      if (response is! List<dynamic>) {
        throw const FormatException('Invalid Show seasons response.');
      }

      final List<ShowDetailsLocalSeason> seasons = response
          .map((dynamic rawSeason) {
            if (rawSeason is! Map<String, dynamic>) {
              throw const FormatException('Invalid local Season response.');
            }

            final Object? id = rawSeason['id'];
            final Object? tmdbId = rawSeason['tmdb_id'];
            final Object? seasonNumber = rawSeason['season_number'];

            if (id is! String ||
                id.isEmpty ||
                tmdbId is! int ||
                tmdbId <= 0 ||
                seasonNumber is! int ||
                seasonNumber < 0) {
              throw const FormatException('Invalid local Season data.');
            }

            return ShowDetailsLocalSeason(
              id: id,
              tmdbId: tmdbId,
              seasonNumber: seasonNumber,
            );
          })
          .toList(growable: false);

      return ShowDetailsSeasonsBootstrap(showId: rawShowId, seasons: seasons);
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }

  @override
  Future<List<ShowDetailsEpisode>> getEpisodes({
    required String seasonId,
  }) async {
    try {
      final Response<dynamic> episodesResponse = await _apiClient.get<dynamic>(
        '/seasons/$seasonId/episodes',
      );

      return _episodesFromResponse(episodesResponse.data);
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }

  @override
  Future<List<ShowDetailsEpisode>> syncEpisodes({
    required String seasonId,
  }) async {
    try {
      final Response<dynamic> episodesResponse = await _apiClient.post<dynamic>(
        '/seasons/$seasonId/sync',
      );

      return _episodesFromResponse(episodesResponse.data);
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }

  @override
  Future<List<ShowDetailsSeasonProgress>> getSeasonsProgress({
    required String showId,
  }) async {
    try {
      final Response<dynamic> progressResponse = await _apiClient.get<dynamic>(
        '/shows/$showId/seasons/progress',
      );

      final Object? response = progressResponse.data;

      if (response is! List<dynamic>) {
        throw const FormatException('Invalid Show Seasons progress response.');
      }

      return response
          .map((dynamic rawProgress) {
            if (rawProgress is! Map<String, dynamic>) {
              throw const FormatException('Invalid Season progress response.');
            }

            return _seasonProgressFromJson(rawProgress);
          })
          .toList(growable: false);
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }

  @override
  Future<ShowDetailsSeasonProgress> getSeasonProgress({
    required String seasonId,
  }) async {
    try {
      final Response<dynamic> progressResponse = await _apiClient.get<dynamic>(
        '/seasons/$seasonId/progress',
      );

      final Object? response = progressResponse.data;

      if (response is! Map<String, dynamic>) {
        throw const FormatException('Invalid Season progress response.');
      }

      return _seasonProgressFromJson(response);
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }

  ShowDetailsSeasonProgress _seasonProgressFromJson(Map<String, dynamic> json) {
    final Object? seasonId = json['season_id'];

    final Object? watchedEpisodes = json['watched_episodes'];

    final Object? totalEpisodes = json['total_episodes'];

    final Object? progressPercentage = json['progress_percentage'];

    final Object? airedEpisodes = json['aired_episodes'];

    final Object? watchedAiredEpisodes = json['watched_aired_episodes'];

    final Object? airedProgressPercentage = json['aired_progress_percentage'];

    final Object? caughtUp = json['caught_up'];

    if (seasonId is! String ||
        seasonId.isEmpty ||
        watchedEpisodes is! int ||
        watchedEpisodes < 0 ||
        totalEpisodes is! int ||
        totalEpisodes < 0 ||
        progressPercentage is! num ||
        progressPercentage < 0 ||
        progressPercentage > 100 ||
        airedEpisodes is! int ||
        airedEpisodes < 0 ||
        watchedAiredEpisodes is! int ||
        watchedAiredEpisodes < 0 ||
        airedProgressPercentage is! num ||
        airedProgressPercentage < 0 ||
        airedProgressPercentage > 100 ||
        caughtUp is! bool) {
      throw const FormatException('Invalid Season progress data.');
    }

    return ShowDetailsSeasonProgress(
      seasonId: seasonId,
      watchedEpisodes: watchedEpisodes,
      totalEpisodes: totalEpisodes,
      progressPercentage: progressPercentage.toDouble(),
      airedEpisodes: airedEpisodes,
      watchedAiredEpisodes: watchedAiredEpisodes,
      airedProgressPercentage: airedProgressPercentage.toDouble(),
      caughtUp: caughtUp,
    );
  }

  List<ShowDetailsEpisode> _episodesFromResponse(Object? response) {
    if (response is! List<dynamic>) {
      throw const FormatException('Invalid Season episodes response.');
    }

    return response
        .map((dynamic rawEpisode) {
          if (rawEpisode is! Map<String, dynamic>) {
            throw const FormatException('Invalid Episode response.');
          }

          return _episodeFromJson(rawEpisode);
        })
        .toList(growable: false);
  }

  ShowDetailsEpisode _episodeFromJson(Map<String, dynamic> json) {
    final Object? id = json['id'];
    final Object? tmdbId = json['tmdb_id'];
    final Object? episodeNumber = json['episode_number'];
    final Object? title = json['title'];
    final Object? voteAverage = json['vote_average'];
    final Object? voteCount = json['vote_count'];

    if (id is! String ||
        id.isEmpty ||
        tmdbId is! int ||
        tmdbId <= 0 ||
        episodeNumber is! int ||
        episodeNumber < 0 ||
        title is! String ||
        title.trim().isEmpty ||
        voteAverage is! num ||
        voteCount is! int ||
        voteCount < 0) {
      throw const FormatException('Invalid Episode data.');
    }

    return ShowDetailsEpisode(
      id: id,
      tmdbId: tmdbId,
      episodeNumber: episodeNumber,
      title: title.trim(),
      overview: _nullableString(json['overview']),
      airDate: _nullableDate(json['air_date']),
      runtime: _nullableNonNegativeInt(json['runtime']),
      voteAverage: voteAverage.toDouble(),
      voteCount: voteCount,
      stillUrl: _nullableString(json['still_url']),
    );
  }

  String? _nullableString(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is! String) {
      throw const FormatException('Expected a nullable string.');
    }

    final String trimmed = value.trim();

    return trimmed.isEmpty ? null : trimmed;
  }

  DateTime? _nullableDate(Object? value) {
    final String? raw = _nullableString(value);

    if (raw == null) {
      return null;
    }

    final DateTime? parsed = DateTime.tryParse(raw);

    if (parsed == null) {
      throw const FormatException('Invalid Episode date.');
    }

    return parsed;
  }

  int? _nullableNonNegativeInt(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is int && value >= 0) {
      return value;
    }

    throw const FormatException('Invalid nullable non-negative integer.');
  }
}
