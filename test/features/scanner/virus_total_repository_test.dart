import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:fileguard/features/scanner/data/repositories/virus_total_repository_impl.dart';
import 'package:fileguard/features/scanner/domain/models/analysis_stats.dart';
import 'package:fileguard/features/scanner/domain/models/scan_verdict.dart';
import 'package:fileguard/features/scanner/domain/repositories/virus_total_repository.dart';
import 'package:fileguard/features/settings/domain/repositories/api_key_repository.dart';

class MockApiKeyRepository implements ApiKeyRepository {
  String? key = 'test_valid_api_key_123';

  @override
  Future<String?> getApiKey() async => key;

  @override
  Future<void> saveApiKey(String apiKey) async => key = apiKey;

  @override
  Future<void> deleteApiKey() async => key = null;

  @override
  Future<bool> hasApiKey() async => key != null;
}

void main() {
  group('VirusTotalRepositoryImpl Hash Lookup & Classification Tests', () {
    late MockApiKeyRepository mockKeyRepo;

    setUp(() {
      mockKeyRepo = MockApiKeyRepository();
    });

    test('Retorna HashLookupFound e mapeia veredito malicious quando há detecções', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['x-apikey'], equals('test_valid_api_key_123'));
        return http.Response(
          jsonEncode({
            'data': {
              'id': 'abc123sha256',
              'attributes': {
                'sha256': 'abc123sha256',
                'meaningful_name': 'sample_trojan.exe',
                'size': 1024,
                'last_analysis_date': 1672531199,
                'last_analysis_stats': {
                  'malicious': 15,
                  'suspicious': 2,
                  'undetected': 50,
                  'harmless': 0,
                  'timeout': 0,
                  'failure': 0,
                  'type-unsupported': 0,
                },
                'last_analysis_results': {
                  'EngineA': {
                    'engine_name': 'EngineA',
                    'category': 'malicious',
                    'result': 'Trojan.Win32',
                  },
                },
              },
            },
          }),
          200,
        );
      });

      final repository = VirusTotalRepositoryImpl(
        apiKeyRepository: mockKeyRepo,
        client: mockClient,
      );

      final result = await repository.getReportByHash('abc123sha256');
      expect(result, isA<HashLookupFound>());
      final found = result as HashLookupFound;
      expect(found.report.fileName, equals('sample_trojan.exe'));
      expect(found.report.stats.malicious, equals(15));
      expect(found.report.verdict, equals(ScanVerdict.malicious));
    });

    test('Retorna HashLookupNotFound quando HTTP 404 (sem confundir com arquivo seguro)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {'code': 'NotFoundError', 'message': 'File not found'}
          }),
          404,
        );
      });

      final repository = VirusTotalRepositoryImpl(
        apiKeyRepository: mockKeyRepo,
        client: mockClient,
      );

      final result = await repository.getReportByHash('unknown_hash_999');
      expect(result, isA<HashLookupNotFound>());
      final notFound = result as HashLookupNotFound;
      expect(notFound.sha256, equals('unknown_hash_999'));
    });

    test('Retorna HashLookupError com código 429 quando cota excedida', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {'code': 'QuotaExceededError', 'message': 'Quota exceeded'}
          }),
          429,
        );
      });

      final repository = VirusTotalRepositoryImpl(
        apiKeyRepository: mockKeyRepo,
        client: mockClient,
      );

      final result = await repository.getReportByHash('any_hash');
      expect(result, isA<HashLookupError>());
      final error = result as HashLookupError;
      expect(error.statusCode, equals(429));
    });

    test('Mapeia corretamente veredito noDetections e suspicious', () {
      const suspiciousStats = AnalysisStats(malicious: 0, suspicious: 3, undetected: 60);
      expect(ScanVerdict.fromStats(suspiciousStats), equals(ScanVerdict.suspicious));

      const cleanStats = AnalysisStats(malicious: 0, suspicious: 0, undetected: 65, harmless: 2);
      expect(ScanVerdict.fromStats(cleanStats), equals(ScanVerdict.noDetections));

      const inconclusiveStats = AnalysisStats(malicious: 0, suspicious: 0, undetected: 0, harmless: 0, failure: 5);
      expect(ScanVerdict.fromStats(inconclusiveStats), equals(ScanVerdict.inconclusive));
    });
  });
}
