import 'package:flutter_test/flutter_test.dart';
import 'package:fileguard/features/history/data/services/backup_service.dart';
import 'package:fileguard/features/scanner/domain/models/analysis_stats.dart';
import 'package:fileguard/features/scanner/domain/models/scan_report.dart';
import 'package:fileguard/features/scanner/domain/models/scan_verdict.dart';

void main() {
  group('BackupService Tests', () {
    const backupService = BackupService();

    test('Exporta e importa histórico mantendo fidelidade dos dados sem segredos', () {
      final sampleReport = ScanReport(
        id: 'sample_id_1',
        sha256: 'c5784dde94875df13c4535ac133c0049ea014ee16948f31250305522709bd323',
        fileName: 'test_app.apk',
        fileSize: 4096,
        scanDate: DateTime(2026, 11, 10, 20, 0, 0),
        stats: const AnalysisStats(malicious: 0, suspicious: 0, undetected: 68),
        verdict: ScanVerdict.noDetections,
      );

      final jsonString = backupService.exportToJson([sampleReport]);
      expect(jsonString.contains('fileguard_history_backup'), isTrue);
      expect(jsonString.contains('test_app.apk'), isTrue);

      final restoredList = backupService.importFromJson(jsonString);
      expect(restoredList.length, equals(1));
      expect(restoredList.first.fileName, equals('test_app.apk'));
      expect(restoredList.first.stats.undetected, equals(68));
      expect(restoredList.first.verdict, equals(ScanVerdict.noDetections));
    });

    test('Rejeita JSON de formato incompatível', () {
      const invalidJson = '{"format": "other_app", "version": 1}';
      expect(
        () => backupService.importFromJson(invalidJson),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
