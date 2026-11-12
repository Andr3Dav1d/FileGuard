import 'package:fileguard/features/scanner/domain/models/analysis_stats.dart';
import 'package:fileguard/features/scanner/domain/models/engine_result.dart';
import 'package:fileguard/features/scanner/domain/models/scan_report.dart';
import 'package:fileguard/features/scanner/domain/models/scan_verdict.dart';
import 'package:fileguard/features/scanner/domain/models/total_votes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScanReport Parser & Domain Model Tests', () {
    test('1. Converte payload completo do endpoint /files/{id}', () {
      final jsonResponse = {
        'data': {
          'id': '275a021bbfb6489e54d471899f7db9d1663fc695ec2fe2a2c4538aabf651fd0f',
          'type': 'file',
          'attributes': {
            'sha256':
                '275a021bbfb6489e54d471899f7db9d1663fc695ec2fe2a2c4538aabf651fd0f',
            'sha1': '3395856ce81f2b7382dee72602f798b642f14140',
            'md5': '44d88612fea8a8f36de82e1278abb02f',
            'meaningful_name': 'sample_invoice.pdf',
            'names': ['sample_invoice.pdf', 'invoice_nov.pdf'],
            'size': 251904,
            'type_description': 'application/pdf',
            'type_extension': 'pdf',
            'magic': 'PDF document, version 1.4',
            'reputation': -15,
            'tags': ['pdf', 'phishing', 'exploit'],
            'total_votes': {
              'harmless': 1,
              'malicious': 12,
            },
            'last_analysis_date': 1672531199,
            'last_analysis_stats': {
              'malicious': 12,
              'suspicious': 2,
              'undetected': 50,
              'harmless': 6,
              'timeout': 0,
              'confirmed-timeout': 0,
              'failure': 0,
              'type-unsupported': 0,
            },
            'last_analysis_results': {
              'Bitdefender': {
                'category': 'malicious',
                'engine_name': 'Bitdefender',
                'engine_version': '7.2',
                'engine_update': '20261110',
                'method': 'blacklist',
                'result': 'Trojan.Generic',
              },
              'Kaspersky': {
                'category': 'suspicious',
                'engine_name': 'Kaspersky',
                'engine_version': '21.0.1',
                'engine_update': '20261110',
                'method': 'heuristic',
                'result': 'HEUR:Trojan.PDF',
              },
              'ClamAV': {
                'category': 'undetected',
                'engine_name': 'ClamAV',
                'engine_version': '0.105',
                'engine_update': '20261110',
                'method': 'blacklist',
                'result': null,
              },
              'Google': {
                'category': 'harmless',
                'engine_name': 'Google',
                'method': 'blacklist',
                'result': 'clean',
              },
            },
          },
        },
      };

      final report = ScanReport.fromVirusTotalJson(jsonResponse);

      // Verificação de identificadores e hashes
      expect(
        report.sha256,
        equals(
          '275a021bbfb6489e54d471899f7db9d1663fc695ec2fe2a2c4538aabf651fd0f',
        ),
      );
      expect(
        report.sha1,
        equals('3395856ce81f2b7382dee72602f798b642f14140'),
      );
      expect(report.md5, equals('44d88612fea8a8f36de82e1278abb02f'));
      expect(report.fileName, equals('sample_invoice.pdf'));
      expect(report.fileSize, equals(251904));
      expect(report.mimeType, equals('application/pdf'));
      expect(report.fileExtension, equals('pdf'));

      // Reputação, Tags e Votos
      expect(report.reputation, equals(-15));
      expect(report.tags, equals(['pdf', 'phishing', 'exploit']));
      expect(report.totalVotes, isNotNull);
      expect(report.totalVotes!.harmless, equals(1));
      expect(report.totalVotes!.malicious, equals(12));

      // Estatísticas e Veredito
      expect(report.stats.malicious, equals(12));
      expect(report.stats.suspicious, equals(2));
      expect(report.stats.undetected, equals(50));
      expect(report.stats.harmless, equals(6));
      expect(report.stats.totalEngines, equals(70));
      expect(report.verdict, equals(ScanVerdict.malicious));

      // Motores individuais
      expect(report.results.length, equals(4));
      expect(report.threatEngines.length, equals(2));
      expect(report.maliciousEngines.length, equals(1));
      expect(report.suspiciousEngines.length, equals(1));
      expect(report.cleanEngines.length, equals(2));

      final bitdefender = report.results['Bitdefender']!;
      expect(bitdefender.engineName, equals('Bitdefender'));
      expect(bitdefender.category, equals('malicious'));
      expect(bitdefender.engineCategory, equals(EngineCategory.malicious));
      expect(bitdefender.isMalicious, isTrue);
      expect(bitdefender.result, equals('Trojan.Generic'));
      expect(bitdefender.method, equals('blacklist'));
      expect(bitdefender.engineVersion, equals('7.2'));
      expect(bitdefender.engineUpdate, equals('20261110'));

      final kaspersky = report.results['Kaspersky']!;
      expect(kaspersky.isSuspicious, isTrue);
      expect(kaspersky.engineCategory, equals(EngineCategory.suspicious));

      final clamav = report.results['ClamAV']!;
      expect(clamav.isUndetected, isTrue);
      expect(clamav.result, isNull);

      final google = report.results['Google']!;
      expect(google.isHarmless, isTrue);

      expect(
        report.permalink,
        equals(
          'https://www.virustotal.com/gui/file/275a021bbfb6489e54d471899f7db9d1663fc695ec2fe2a2c4538aabf651fd0f',
        ),
      );
    });

    test('2. Converte payload do endpoint /analyses/{id} com resultados em "results" e "meta.file_info"', () {
      final analysisJson = {
        'data': {
          'id': 'Zjc0NWU5MDU2YjFhMTgzYzQxMGFjZDI5ZTFmNWI2MmQ6MTY3MjUzMTI1MA==',
          'type': 'analysis',
          'attributes': {
            'date': 1672531250,
            'status': 'completed',
            'stats': {
              'harmless': 0,
              'type-unsupported': 0,
              'suspicious': 0,
              'confirmed-timeout': 0,
              'timeout': 0,
              'failure': 0,
              'malicious': 0,
              'undetected': 68,
            },
            'results': {
              'Avast': {
                'category': 'undetected',
                'engine_name': 'Avast',
                'engine_version': '22.11',
                'result': null,
                'method': 'blacklist',
                'engine_update': '20261110',
              },
              'ESET-NOD32': {
                'category': 'undetected',
                'engine_name': 'ESET-NOD32',
                'engine_version': '26400',
                'result': null,
                'method': 'blacklist',
                'engine_update': '20261110',
              },
            },
          },
        },
        'meta': {
          'file_info': {
            'sha256':
                'a1b2c3d4e5f67890123456789abcdef0123456789abcdef0123456789abcdef0',
            'sha1': '1234567890abcdef1234567890abcdef12345678',
            'md5': 'abcdef1234567890abcdef1234567890',
            'size': 1048576,
          },
        },
      };

      final report = ScanReport.fromVirusTotalJson(
        analysisJson,
        localFileName: 'safe_document.docx',
      );

      expect(
        report.sha256,
        equals(
          'a1b2c3d4e5f67890123456789abcdef0123456789abcdef0123456789abcdef0',
        ),
      );
      expect(report.sha1, equals('1234567890abcdef1234567890abcdef12345678'));
      expect(report.md5, equals('abcdef1234567890abcdef1234567890'));
      expect(report.fileSize, equals(1048576));
      expect(report.fileName, equals('safe_document.docx'));
      expect(report.stats.undetected, equals(68));
      expect(report.stats.malicious, equals(0));
      expect(report.verdict, equals(ScanVerdict.noDetections));
      expect(report.results.length, equals(2));
      expect(report.results.containsKey('Avast'), isTrue);
      expect(report.results.containsKey('ESET-NOD32'), isTrue);
      expect(report.threatEngines, isEmpty);
      expect(report.cleanEngines.length, equals(2));
    });

    test('3. Tolera campos ausentes e nulos graciosamente', () {
      final minimalJson = {
        'data': {
          'id': 'minimal_sha256',
          'attributes': <String, dynamic>{},
        },
      };

      final report = ScanReport.fromVirusTotalJson(minimalJson);

      expect(report.sha256, equals('minimal_sha256'));
      expect(report.md5, isNull);
      expect(report.sha1, isNull);
      expect(report.reputation, isNull);
      expect(report.tags, isEmpty);
      expect(report.totalVotes, isNull);
      expect(report.fileName, equals('Arquivo sem nome'));
      expect(report.fileSize, equals(0));
      expect(report.results, isEmpty);
      expect(report.verdict, equals(ScanVerdict.inconclusive));
    });

    test('3b. Não atribui analysisId de data.id a sha256 quando payload for do tipo analysis', () {
      final analysisWithoutHash = {
        'data': {
          'id': 'Zjc0NWU5MDU2YjFhMTgzYzQxMGFjZDI5ZTFmNWI2MmQ6MTY3MjUzMTI1MA==',
          'type': 'analysis',
          'attributes': {
            'status': 'completed',
            'stats': {'malicious': 0, 'undetected': 10},
          },
        },
      };

      final report = ScanReport.fromVirusTotalJson(
        analysisWithoutHash,
        fallbackSha256: 'fallback_hex_sha256',
      );

      // O analysisId fica preservado em id, mas sha256 não recebe a string base64
      expect(report.id, equals('Zjc0NWU5MDU2YjFhMTgzYzQxMGFjZDI5ZTFmNWI2MmQ6MTY3MjUzMTI1MA=='));
      expect(report.sha256, equals('fallback_hex_sha256'));
    });

    test('4. Validação completa das categorias de EngineCategory', () {
      final categories = {
        'malicious': EngineCategory.malicious,
        'suspicious': EngineCategory.suspicious,
        'undetected': EngineCategory.undetected,
        'harmless': EngineCategory.harmless,
        'timeout': EngineCategory.timeout,
        'confirmed-timeout': EngineCategory.timeout,
        'failure': EngineCategory.failure,
        'type-unsupported': EngineCategory.typeUnsupported,
        'type_unsupported': EngineCategory.typeUnsupported,
        'something_else': EngineCategory.unknown,
        null: EngineCategory.unknown,
      };

      categories.forEach((input, expected) {
        expect(EngineCategory.fromString(input), equals(expected));
      });

      final timeoutEngine = const EngineResult(
        engineName: 'SlowEngine',
        category: 'confirmed-timeout',
      );
      expect(timeoutEngine.isTimeout, isTrue);
      expect(timeoutEngine.isMalicious, isFalse);

      final failedEngine = const EngineResult(
        engineName: 'BrokenEngine',
        category: 'failure',
      );
      expect(failedEngine.isFailure, isTrue);

      final unsupportedEngine = const EngineResult(
        engineName: 'OddEngine',
        category: 'type-unsupported',
      );
      expect(unsupportedEngine.isTypeUnsupported, isTrue);
    });

    test('5. Serialização e desserialização completa via toJson e fromJson', () {
      final originalReport = ScanReport(
        id: 'full_report_id',
        sha256: 'sha256_value',
        md5: 'md5_value',
        sha1: 'sha1_value',
        fileName: 'report_sample.exe',
        fileSize: 4096,
        scanDate: DateTime(2026, 11, 10, 9, 41),
        stats: const AnalysisStats(
          malicious: 3,
          suspicious: 1,
          undetected: 60,
          harmless: 2,
          timeout: 1,
          failure: 1,
          typeUnsupported: 1,
        ),
        verdict: ScanVerdict.malicious,
        permalink: 'https://www.virustotal.com/gui/file/sha256_value',
        mimeType: 'application/x-dosexec',
        fileExtension: 'exe',
        reputation: -20,
        tags: const ['peexe', 'trojan'],
        totalVotes: const TotalVotes(harmless: 2, malicious: 15),
        results: {
          'Engine1': const EngineResult(
            engineName: 'Engine1',
            category: 'malicious',
            result: 'Win32.Malware',
            method: 'blacklist',
            engineVersion: '1.0',
            engineUpdate: '20261110',
          ),
        },
      );

      final jsonMap = originalReport.toJson();
      final restoredReport = ScanReport.fromJson(jsonMap);

      expect(restoredReport.id, equals(originalReport.id));
      expect(restoredReport.sha256, equals(originalReport.sha256));
      expect(restoredReport.md5, equals(originalReport.md5));
      expect(restoredReport.sha1, equals(originalReport.sha1));
      expect(restoredReport.fileName, equals(originalReport.fileName));
      expect(restoredReport.fileSize, equals(originalReport.fileSize));
      expect(
        restoredReport.scanDate.millisecondsSinceEpoch,
        equals(originalReport.scanDate.millisecondsSinceEpoch),
      );
      expect(restoredReport.stats.malicious, equals(originalReport.stats.malicious));
      expect(restoredReport.verdict, equals(originalReport.verdict));
      expect(restoredReport.permalink, equals(originalReport.permalink));
      expect(restoredReport.mimeType, equals(originalReport.mimeType));
      expect(restoredReport.fileExtension, equals(originalReport.fileExtension));
      expect(restoredReport.reputation, equals(originalReport.reputation));
      expect(restoredReport.tags, equals(originalReport.tags));
      expect(restoredReport.totalVotes, equals(originalReport.totalVotes));
      expect(restoredReport.results.length, equals(1));
      expect(
        restoredReport.results['Engine1']!.result,
        equals('Win32.Malware'),
      );
    });

    test('6. TotalVotes igualdade e serialização', () {
      const votes1 = TotalVotes(harmless: 5, malicious: 10);
      const votes2 = TotalVotes(harmless: 5, malicious: 10);
      const votes3 = TotalVotes(harmless: 0, malicious: 0);

      expect(votes1, equals(votes2));
      expect(votes1 == votes3, isFalse);

      final json = votes1.toJson();
      final parsed = TotalVotes.fromJson(json);
      expect(parsed, equals(votes1));
    });
  });
}
