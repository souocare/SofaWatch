import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/auth/data/storage/in_memory_access_token_store.dart';

void main() {
  group('InMemoryAccessTokenStore', () {
    test('starts without access token', () {
      final InMemoryAccessTokenStore store = InMemoryAccessTokenStore();

      expect(store.token, isNull);
    });

    test('stores access token in memory', () {
      final InMemoryAccessTokenStore store = InMemoryAccessTokenStore();

      store.save('access-token');

      expect(store.token, 'access-token');
    });

    test('normalizes access token before storing', () {
      final InMemoryAccessTokenStore store = InMemoryAccessTokenStore();

      store.save('  access-token  ');

      expect(store.token, 'access-token');
    });

    test('clears access token', () {
      final InMemoryAccessTokenStore store = InMemoryAccessTokenStore();

      store.save('access-token');

      store.clear();

      expect(store.token, isNull);
    });

    test('rejects empty access token', () {
      final InMemoryAccessTokenStore store = InMemoryAccessTokenStore();

      expect(() => store.save('   '), throwsArgumentError);
    });
  });
}
