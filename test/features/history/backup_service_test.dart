import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:fileguard/features/history/data/services/backup_service.dart';
import 'package:fileguard/features/scanner/domain/models/analysis_stats.dart';
import 'package:fileguard/features/scanner/domain/models/engine_result.dart';
import 'package:fileguard/features/scanner/domain/models/scan_report.dart';
import 'package:fileguard/features/scanner/domain/models/scan_verdict.dart';
import 'package:fileguard/features/scanner/domain/models/total_votes.dart';

void main() {
  group('BackupService Tests', () {
    const backupService = BackupService();

    test('1. Exporta e restaura backup v2 completo com motores, hashes e metadados', () {
      final sampleReport = ScanReport(
        id: 'sample_id_v2',
        sha256: 'c5784dde94875df13c4535ac133c0049ea014ee16948f31250305522709bd323',
        md5: '44d88612fea8a8f36de82e1278abb02f',
        sha1: '3395856ce81f2b7382dee72602f798b642f14140',
        fileName: 'malware_sample.exe',
        fileSize: 1048576,
        scanDate: DateTime(2026, 11, 10, 20, 0, 0),
        stats: const AnalysisStats(
          malicious: 2,
          suspicious: 1,
          undetected: 65,
          harmless: 2,
        ),
        verdict: ScanVerdict.malicious,
        permalink: 'https://www.virustotal.com/gui/file/c5784dde94875df13c4535ac133c0049ea014ee16948f31250305522709bd323',
        mimeType: 'application/x-dosexec',
        fileExtension: 'exe',
        reputation: -35,
        tags: const ['peexe', 'trojan', 'signed'],
        totalVotes: const TotalVotes(harmless: 1, malicious: 18),
        results: {
          'Bitdefender': const EngineResult(
            engineName: 'Bitdefender',
            category: 'malicious',
            result: 'Trojan.Generic',
            method: 'blacklist',
            engineVersion: '7.2',
            engineUpdate: '20261110',
          ),
          'Kaspersky': const EngineResult(
            engineName: 'Kaspersky',
            category: 'suspicious',
            result: 'HEUR:Trojan.Win32',
            method: 'heuristic',
            engineVersion: '21.0.1',
            engineUpdate: '20261110',
          ),
        },
      );

      final jsonString = backupService.exportToJson([sampleReport]);

      // Validação do envelope e versão 2
      final Map<String, dynamic> decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      expect(decoded['format'], equals('fileguard_history_backup'));
      expect(decoded['version'], equals(2));
      expect(decoded['total_records'], equals(1));

      // Não deve conter chaves de API nem credenciais
      expect(jsonString.contains('api_key'), isFalse);
      expect(jsonString.contains('apikey'), isFalse);
      expect(jsonString.contains('token'), isFalse);

      // Restauração completa
      final restoredList = backupService.importFromJson(jsonString);
      expect(restoredList.length, equals(1));

      final restored = restoredList.first;
      expect(restored.id, equals('sample_id_v2'));
      expect(restored.sha256, equals('c5784dde94875df13c4535ac133c0049ea014ee16948f31250305522709bd323'));
      expect(restored.md5, equals('44d88612fea8a8f36de82e1278abb02f'));
      expect(restored.sha1, equals('3395856ce81f2b7382dee72602f798b642f14140'));
      expect(restored.fileName, equals('malware_sample.exe'));
      expect(restored.fileSize, equals(1048576));
      expect(restored.fileExtension, equals('exe'));
      expect(restored.reputation, equals(-35));
      expect(restored.tags, equals(['peexe', 'trojan', 'signed']));
      expect(restored.totalVotes, equals(const TotalVotes(harmless: 1, malicious: 18)));
      expect(restored.results.length, equals(2));
      expect(restored.results['Bitdefender']!.result, equals('Trojan.Generic'));
      expect(restored.results['Kaspersky']!.isSuspicious, isTrue);
    });

    test('2. Importa perfeitamente backups legados da versão 1', () {
      const v1BackupJson = '''
      {
        "format": "fileguard_history_backup",
        "version": 1,
        "exported_at": "2026-11-10T15:30:00.000Z",
        "total_records": 1,
        "reports": [
          {
            "id": "legacy_report_1",
            "sha256": "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
            "file_name": "legacy_doc.pdf",
            "file_size": 2048,
            "scan_date": "2026-11-10T15:00:00.000Z",
            "verdict": "noDetections",
            "stats": {
              "malicious": 0,
              "suspicious": 0,
              "undetected": 70,
              "harmless": 0,
              "timeout": 0,
              "failure": 0,
              "type-unsupported": 0
            },
            "permalink": "https://www.virustotal.com/gui/file/abcdef",
            "mime_type": "application/pdf"
          }
        ]
      }
      ''';

      final restoredList = backupService.importFromJson(v1BackupJson);
      expect(restoredList.length, equals(1));

      final restored = restoredList.first;
      expect(restored.id, equals('legacy_report_1'));
      expect(restored.fileName, equals('legacy_doc.pdf'));
      expect(restored.verdict, equals(ScanVerdict.noDetections));
      expect(restored.stats.undetected, equals(70));
      // Campos v2 ausentes devem assumir defaults seguros
      expect(restored.results, isEmpty);
      expect(restored.md5, isNull);
      expect(restored.sha1, isNull);
      expect(restored.tags, isEmpty);
      expect(restored.reputation, isNull);
      expect(restored.totalVotes, isNull);
      expect(restored.fileExtension, isNull);
    });

    test('3. Rejeita formato de backup incompatível', () {
      const invalidJson = '{"format": "other_app", "version": 2}';
      expect(
        () => backupService.importFromJson(invalidJson),
        throwsA(isA<FormatException>()),
      );
    });

    test('4. Tolera registros corrompidos ou malformados na lista de relatórios', () {
      const corruptedItemBackup = '''
      {
        "format": "fileguard_history_backup",
        "version": 2,
        "exported_at": "2026-11-10T15:30:00.000Z",
        "total_records": 3,
        "reports": [
          "string_invalida_nao_objeto",
          null,
          {
            "id": "valid_entry",
            "sha256": "valid_hash",
            "file_name": "valid.txt",
            "file_size": 100,
            "scan_date": "2026-11-10T12:00:00.000Z",
            "verdict": "noDetections",
            "stats": {}
          }
        ]
      }
      ''';

      final restoredList = backupService.importFromJson(corruptedItemBackup);
      expect(restoredList.length, equals(1));
      expect(restoredList.first.id, equals('valid_entry'));
      expect(restoredList.first.fileName, equals('valid.txt'));
    });
  });
}
