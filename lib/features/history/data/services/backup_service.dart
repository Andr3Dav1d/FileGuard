import 'dart:convert';
import 'package:fileguard/features/scanner/domain/models/analysis_stats.dart';
import 'package:fileguard/features/scanner/domain/models/scan_report.dart';
import 'package:fileguard/features/scanner/domain/models/scan_verdict.dart';

/// Serviço para exportação e importação de backup local do histórico em JSON.
/// Nunca inclui API Keys ou credenciais.
class BackupService {
  const BackupService();

  static const int _currentBackupVersion = 1;

  /// Gera representação JSON do histórico para backup offline.
  String exportToJson(List<ScanReport> reports) {
    final Map<String, dynamic> payload = {
      'format': 'fileguard_history_backup',
      'version': _currentBackupVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'total_records': reports.length,
      'reports': reports.map((r) => {
        'id': r.id,
        'sha256': r.sha256,
        'file_name': r.fileName,
        'file_size': r.fileSize,
        'scan_date': r.scanDate.toIso8601String(),
        'verdict': r.verdict.name,
        'stats': r.stats.toJson(),
        'permalink': r.permalink,
        'mime_type': r.mimeType,
      }).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Restaura uma lista de relatórios a partir de um JSON de backup validado.
  List<ScanReport> importFromJson(String rawJson) {
    final Map<String, dynamic> data = jsonDecode(rawJson) as Map<String, dynamic>;

    if (data['format'] != 'fileguard_history_backup') {
      throw const FormatException('Arquivo de backup inválido ou incompatível.');
    }

    final rawReports = data['reports'] as List<dynamic>? ?? [];
    return rawReports.map((item) {
      final map = item as Map<String, dynamic>;
      final stats = AnalysisStats.fromJson(map['stats'] as Map<String, dynamic>? ?? {});
      final verdictName = map['verdict'] as String? ?? 'inconclusive';
      final verdict = ScanVerdict.values.firstWhere(
        (v) => v.name == verdictName,
        orElse: () => ScanVerdict.inconclusive,
      );

      final dateStr = map['scan_date'] as String?;
      final scanDate = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();

      return ScanReport(
        id: map['id'] as String? ?? map['sha256'] as String? ?? '',
        sha256: map['sha256'] as String? ?? '',
        fileName: map['file_name'] as String? ?? 'Arquivo',
        fileSize: (map['file_size'] as num?)?.toInt() ?? 0,
        scanDate: scanDate,
        stats: stats,
        verdict: verdict,
        permalink: map['permalink'] as String?,
        mimeType: map['mime_type'] as String?,
      );
    }).toList();
  }
}
