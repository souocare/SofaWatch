import 'dart:convert';

import 'package:sofawatch/core/server/models/server_configuration.dart';
import 'package:sofawatch/core/server/repositories/server_configuration_repository.dart';
import 'package:sofawatch/core/storage/key_value_store.dart';

class SharedPreferencesServerConfigurationRepository
    implements ServerConfigurationRepository {
  SharedPreferencesServerConfigurationRepository({required this._storage});

  static const String storageKey = 'sofawatch.server_configuration.v1';

  final KeyValueStore _storage;

  @override
  Future<ServerConfiguration?> load() async {
    final String? storedValue = await _storage.getString(storageKey);

    if (storedValue == null || storedValue.trim().isEmpty) {
      return null;
    }

    try {
      final Object? decodedValue = jsonDecode(storedValue);

      if (decodedValue is! Map<String, dynamic>) {
        await clear();

        return null;
      }

      return ServerConfiguration.fromJson(decodedValue);
    } on FormatException {
      await clear();

      return null;
    } on TypeError {
      await clear();

      return null;
    }
  }

  @override
  Future<void> save(ServerConfiguration configuration) {
    final String encodedConfiguration = jsonEncode(configuration.toJson());

    return _storage.setString(storageKey, encodedConfiguration);
  }

  @override
  Future<void> clear() {
    return _storage.remove(storageKey);
  }
}
