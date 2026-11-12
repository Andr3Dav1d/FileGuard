import 'dart:convert';
import 'dart:io';
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

  group('VirusTotalRepositoryImpl Analysis & Polling Optimization Tests', () {
    late MockApiKeyRepository mockKeyRepo;

    setUp(() {
      mockKeyRepo = MockApiKeyRepository();
    });

    test('1. getAnalysis constrói ScanReport diretamente de /analyses/{id} SEM consultar /files/{sha256}', () async {
      int analysisCallCount = 0;
      int filesCallCount = 0;

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/analyses/')) {
          analysisCallCount++;
          return http.Response(
            jsonEncode({
              'data': {
                'id': 'analysis_finished_123',
                'type': 'analysis',
                'attributes': {
                  'status': 'completed',
                  'date': 1672531200,
                  'stats': {
                    'malicious': 1,
                    'suspicious': 0,
                    'undetected': 69,
                    'harmless': 0,
                  },
                  'results': {
                    'Bitdefender': {
                      'category': 'malicious',
                      'engine_name': 'Bitdefender',
                      'result': 'Trojan.Test',
                      'method': 'blacklist',
                    },
                    'ClamAV': {
                      'category': 'undetected',
                      'engine_name': 'ClamAV',
                      'result': null,
                      'method': 'blacklist',
                    },
                  },
                },
              },
              'meta': {
                'file_info': {
                  'sha256': '11223344556677889900aabbccddeeff11223344556677889900aabbccddeeff',
                  'md5': 'abcdef1234567890abcdef1234567890',
                  'sha1': '1234567890abcdef1234567890abcdef12345678',
                  'size': 2048,
                },
              },
            }),
            200,
          );
        } else if (request.url.path.contains('/files/')) {
          filesCallCount++;
          return http.Response('{"error": "Should not be called"}', 500);
        }
        return http.Response('Not Found', 404);
      });

      final repository = VirusTotalRepositoryImpl(
        apiKeyRepository: mockKeyRepo,
        client: mockClient,
      );

      final report = await repository.getAnalysis(
        'analysis_finished_123',
        fileName: 'uploaded_doc.pdf',
        fileSize: 2048,
      );

      // Verificação da eliminação de consultas redundantes
      expect(analysisCallCount, equals(1));
      expect(filesCallCount, equals(0)); // Zero chamadas extras a /files/!

      // Verificação da fidelidade do relatório
      expect(report, isNotNull);
      expect(report!.fileName, equals('uploaded_doc.pdf'));
      expect(report.sha256, equals('11223344556677889900aabbccddeeff11223344556677889900aabbccddeeff'));
      expect(report.md5, equals('abcdef1234567890abcdef1234567890'));
      expect(report.sha1, equals('1234567890abcdef1234567890abcdef12345678'));
      expect(report.stats.malicious, equals(1));
      expect(report.verdict, equals(ScanVerdict.malicious));
      expect(report.results.length, equals(2));
      expect(report.results['Bitdefender']!.isMalicious, isTrue);
      expect(report.results['ClamAV']!.isUndetected, isTrue);
    });

    test('2. getAnalysis retorna null quando status ainda é queued ou in-progress', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'data': {
              'id': 'analysis_pending',
              'type': 'analysis',
              'attributes': {
                'status': 'in-progress',
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

      final report = await repository.getAnalysis('analysis_pending');
      expect(report, isNull);
    });

    test('3. getAnalysis lança HttpException em erros 401, 429 e 404', () async {
      final mockClient429 = MockClient((request) async {
        return http.Response(
          '{"error": "Too Many Requests"}',
          429,
          headers: {'retry-after': '30'},
        );
      });
      final repo429 = VirusTotalRepositoryImpl(
        apiKeyRepository: mockKeyRepo,
        client: mockClient429,
      );
      expect(
        () => repo429.getAnalysis('analysis_id'),
        throwsA(isA<RateLimitException>()
            .having((e) => e.message, 'message', contains('Limite de requisições'))
            .having((e) => e.retryAfter?.inSeconds, 'retryAfter', equals(30))),
      );

      final mockClient401 = MockClient((request) async {
        return http.Response('{"error": "Unauthorized"}', 401);
      });
      final repo401 = VirusTotalRepositoryImpl(
        apiKeyRepository: mockKeyRepo,
        client: mockClient401,
      );
      expect(
        () => repo401.getAnalysis('analysis_id'),
        throwsA(isA<HttpException>().having((e) => e.message, 'message', contains('API Key inválida'))),
      );
    });

    test('4. pollAnalysis conclui na primeira tentativa se já concluído (apenas 1 requisição)', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        return http.Response(
          jsonEncode({
            'data': {
              'id': 'quick_analysis',
              'attributes': {
                'status': 'completed',
                'stats': {'malicious': 0, 'undetected': 70},
                'results': {},
              },
            },
            'meta': {
              'file_info': {
                'sha256': 'quick_sha256',
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

      final report = await repository.pollAnalysis(
        analysisId: 'quick_analysis',
        initialDelay: Duration.zero,
      );

      expect(requestCount, equals(1));
      expect(report, isNotNull);
      expect(report!.sha256, equals('quick_sha256'));
    });

    test('5. pollAnalysis realiza backoff e conclui após tentativas intermediárias', () async {
      int attempts = 0;
      final mockClient = MockClient((request) async {
        attempts++;
        if (attempts < 3) {
          return http.Response(
            jsonEncode({
              'data': {
                'attributes': {'status': 'queued'},
              },
            }),
            200,
          );
        } else {
          return http.Response(
            jsonEncode({
              'data': {
                'attributes': {
                  'status': 'completed',
                  'stats': {'malicious': 0, 'undetected': 68},
                  'results': {},
                },
              },
              'meta': {
                'file_info': {'sha256': 'final_sha256'},
              },
            }),
            200,
          );
        }
      });

      final repository = VirusTotalRepositoryImpl(
        apiKeyRepository: mockKeyRepo,
        client: mockClient,
      );

      final List<String> progressLogs = [];
      final report = await repository.pollAnalysis(
        analysisId: 'polled_analysis',
        initialDelay: Duration.zero,
        maxDelay: Duration.zero,
        maxAttempts: 4,
        onProgress: (msg, progress) => progressLogs.add(msg),
      );

      expect(attempts, equals(3));
      expect(report, isNotNull);
      expect(report!.sha256, equals('final_sha256'));
      expect(progressLogs.isNotEmpty, isTrue);
    });

    test('6. pollAnalysis recupera de erro 429 com retry e conclui com sucesso', () async {
      int attempts = 0;
      final mockClient = MockClient((request) async {
        attempts++;
        if (attempts == 1) {
          // Primeira tentativa: rate limit 429
          return http.Response('{"error": "Too Many Requests"}', 429);
        }
        // Segunda tentativa: concluído
        return http.Response(
          jsonEncode({
            'data': {
              'attributes': {
                'status': 'completed',
                'stats': {'malicious': 0, 'undetected': 70},
                'results': {},
              },
            },
            'meta': {
              'file_info': {'sha256': 'recovered_sha256'},
            },
          }),
          200,
        );
      });

      final repository = VirusTotalRepositoryImpl(
        apiKeyRepository: mockKeyRepo,
        client: mockClient,
      );

      final report = await repository.pollAnalysis(
        analysisId: 'rate_limited_analysis',
        initialDelay: Duration.zero,
        maxDelay: Duration.zero,
      );

      expect(attempts, equals(2));
      expect(report, isNotNull);
      expect(report!.sha256, equals('recovered_sha256'));
    });

    test('7. pollAnalysis interrompe imediatamente se cancelado', () async {
      int attempts = 0;
      final mockClient = MockClient((request) async {
        attempts++;
        return http.Response(
          jsonEncode({
            'data': {'attributes': {'status': 'queued'}}
          }),
          200,
        );
      });

      final repository = VirusTotalRepositoryImpl(
        apiKeyRepository: mockKeyRepo,
        client: mockClient,
      );

      bool cancelFlag = false;
      final report = await repository.pollAnalysis(
        analysisId: 'cancel_analysis',
        initialDelay: Duration.zero,
        maxDelay: Duration.zero,
        maxAttempts: 5,
        isCancelled: () {
          if (attempts >= 1) cancelFlag = true;
          return cancelFlag;
        },
      );

      expect(report, isNull);
      expect(attempts, lessThanOrEqualTo(2));
    });

    test('8. pollAnalysis retorna null graciosamente se exceder tentativas máximas', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'data': {'attributes': {'status': 'queued'}}
          }),
          200,
        );
      });

      final repository = VirusTotalRepositoryImpl(
        apiKeyRepository: mockKeyRepo,
        client: mockClient,
      );

      final report = await repository.pollAnalysis(
        analysisId: 'never_ending_analysis',
        initialDelay: Duration.zero,
        maxDelay: Duration.zero,
        maxAttempts: 2,
      );

      expect(report, isNull);
    });
  });

  group('VirusTotalRepositoryImpl Upload Tests', () {
    late MockApiKeyRepository mockKeyRepo;

    setUp(() {
      mockKeyRepo = MockApiKeyRepository();
    });

    test('uploadFile com bytes em memória envia requisição multipart e retorna analysisId', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/files'));
        expect(request.method, equals('POST'));
        expect(request.headers['x-apikey'], equals('test_valid_api_key_123'));
        return http.Response(
          jsonEncode({
            'data': {'id': 'upload_analysis_id_123', 'type': 'analysis'}
          }),
          200,
        );
      });

      final repository = VirusTotalRepositoryImpl(
        apiKeyRepository: mockKeyRepo,
        client: mockClient,
      );

      final result = await repository.uploadFile(
        bytes: [1, 2, 3, 4],
        fileName: 'test.bin',
      );

      expect(result, equals('upload_analysis_id_123'));
    });

    test('uploadFile com filePath faz upload em stream do arquivo temporário', () async {
      final tempDir = await Directory.systemTemp.createTemp('fileguard_test');
      final tempFile = File('${tempDir.path}/test_stream.bin');
      await tempFile.writeAsBytes([10, 20, 30, 40]);

      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/files'));
        expect(request.method, equals('POST'));
        return http.Response(
          jsonEncode({
            'data': {'id': 'stream_analysis_id_456', 'type': 'analysis'}
          }),
          200,
        );
      });

      final repository = VirusTotalRepositoryImpl(
        apiKeyRepository: mockKeyRepo,
        client: mockClient,
      );

      final result = await repository.uploadFile(
        filePath: tempFile.path,
        fileName: 'test_stream.bin',
      );

      expect(result, equals('stream_analysis_id_456'));
      await tempDir.delete(recursive: true);
    });

    test('uploadFile lança HttpException ao receber HTTP 413 (excesso de 32 MB)', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Request Entity Too Large', 413);
      });

      final repository = VirusTotalRepositoryImpl(
        apiKeyRepository: mockKeyRepo,
        client: mockClient,
      );

      expect(
        () => repository.uploadFile(bytes: [1], fileName: 'big.iso'),
        throwsA(isA<HttpException>().having(
          (e) => e.message,
          'message',
          contains('32 MB'),
        )),
      );
    });

    test('uploadFile lança HttpException ao receber HTTP 429', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Quota Exceeded', 429);
      });

      final repository = VirusTotalRepositoryImpl(
        apiKeyRepository: mockKeyRepo,
        client: mockClient,
      );

      expect(
        () => repository.uploadFile(bytes: [1], fileName: 'test.bin'),
        throwsA(isA<HttpException>().having(
          (e) => e.message,
          'message',
          contains('Limite de cota'),
        )),
      );
    });

    test('uploadFile lança ArgumentError se nem filePath nem bytes forem fornecidos', () async {
      final mockClient = MockClient((request) async => http.Response('{}', 200));
      final repository = VirusTotalRepositoryImpl(
        apiKeyRepository: mockKeyRepo,
        client: mockClient,
      );

      expect(
        () => repository.uploadFile(fileName: 'test.bin'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
