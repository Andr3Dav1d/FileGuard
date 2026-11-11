import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:fileguard/features/scanner/data/datasources/virus_total_api_client.dart';
import 'package:fileguard/features/settings/domain/models/api_key_status.dart';
import 'package:fileguard/features/settings/domain/repositories/api_key_repository.dart';

/// Fake em memória para testar ApiKeyRepository sem depender do Keystore real.
class FakeApiKeyRepository implements ApiKeyRepository {
  String? _key;

  @override
  Future<String?> getApiKey() async => _key;

  @override
  Future<void> saveApiKey(String apiKey) async {
    _key = apiKey;
  }

  @override
  Future<void> deleteApiKey() async {
    _key = null;
  }

  @override
  Future<bool> hasApiKey() async => _key != null && _key!.isNotEmpty;
}

void main() {
  group('ApiKey Repository & Storage Tests', () {
    late FakeApiKeyRepository repository;

    setUp(() {
      repository = FakeApiKeyRepository();
    });

    test('Inicializa sem chave salva', () async {
      expect(await repository.hasApiKey(), isFalse);
      expect(await repository.getApiKey(), isNull);
    });

    test('Salva, recupera e remove chave sem expor segredos', () async {
      const testKey = 'abc1234567890def1234567890def1234567890def1234567890def12345678';
      await repository.saveApiKey(testKey);

      expect(await repository.hasApiKey(), isTrue);
      expect(await repository.getApiKey(), equals(testKey));

      await repository.deleteApiKey();
      expect(await repository.hasApiKey(), isFalse);
      expect(await repository.getApiKey(), isNull);
    });
  });

  group('VirusTotalApiClient Tests', () {
    test('Retorna ApiKeyStatus.valid quando HTTP 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['x-apikey'], equals('valid_key_test'));
        return http.Response(
          jsonEncode({
            'data': {
              'id': 'valid_key_test',
              'type': 'user',
              'attributes': {'status': 'active'},
            }
          }),
          200,
        );
      });

      final client = VirusTotalApiClient(client: mockClient);
      final status = await client.validateApiKey('valid_key_test');

      expect(status, equals(ApiKeyStatus.valid));
    });

    test('Retorna ApiKeyStatus.invalid quando HTTP 401', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {'code': 'UserInvalidArgumentError', 'message': 'Invalid API Key'}
          }),
          401,
        );
      });

      final client = VirusTotalApiClient(client: mockClient);
      final status = await client.validateApiKey('bad_key');

      expect(status, equals(ApiKeyStatus.invalid));
    });

    test('Retorna ApiKeyStatus.quotaExceeded quando HTTP 429', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {'code': 'QuotaExceededError', 'message': 'Quota exceeded'}
          }),
          429,
        );
      });

      final client = VirusTotalApiClient(client: mockClient);
      final status = await client.validateApiKey('quota_key');

      expect(status, equals(ApiKeyStatus.quotaExceeded));
    });

    test('Retorna ApiKeyStatus.notConfigured para chave vazia', () async {
      final client = VirusTotalApiClient();
      final status = await client.validateApiKey('   ');

      expect(status, equals(ApiKeyStatus.notConfigured));
    });
  });
}
