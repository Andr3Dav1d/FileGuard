import 'dart:convert';
import 'package:fileguard/features/scanner/domain/models/analysis_stats.dart';
import 'package:fileguard/features/scanner/domain/models/engine_result.dart';
import 'package:fileguard/features/scanner/domain/models/scan_report.dart';
import 'package:fileguard/features/scanner/domain/models/scan_verdict.dart';
import 'package:fileguard/features/scanner/domain/models/total_votes.dart';

/// Serviço para exportação e importação de backup local do histórico em JSON.
/// Nunca inclui API Keys, credenciais ou tokens sensíveis.
class BackupService {
  const BackupService();

  static const int _currentBackupVersion = 2;

  /// Gera representação JSON do histórico para backup offline seguro.
  String exportToJson(List<ScanReport> reports) {
    final Map<String, dynamic> payload = {
      'format': 'fileguard_history_backup',
      'version': _currentBackupVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'total_records': reports.length,
      'reports': reports.map((r) => {
        'id': r.id,
        'sha256': r.sha256,
        if (r.md5 != null) 'md5': r.md5,
        if (r.sha1 != null) 'sha1': r.sha1,
        'file_name': r.fileName,
        'file_size': r.fileSize,
        'scan_date': r.scanDate.toIso8601String(),
        'verdict': r.verdict.name,
        'stats': r.stats.toJson(),
        if (r.permalink != null) 'permalink': r.permalink,
        if (r.mimeType != null) 'mime_type': r.mimeType,
        if (r.fileExtension != null) 'file_extension': r.fileExtension,
        if (r.reputation != null) 'reputation': r.reputation,
        if (r.tags.isNotEmpty) 'tags': r.tags,
        if (r.totalVotes != null) 'total_votes': r.totalVotes!.toJson(),
        if (r.results.isNotEmpty)
          'results': r.results.map((k, v) => MapEntry(k, v.toJson())),
      }).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Restaura uma lista de relatórios a partir de um JSON de backup validado.
  /// Suporta tanto o formato v1 (legado) quanto o formato v2 (detalhado).
  List<ScanReport> importFromJson(String rawJson) {
    final Map<String, dynamic> data = jsonDecode(rawJson) as Map<String, dynamic>;

    if (data['format'] != 'fileguard_history_backup') {
      throw const FormatException('Arquivo de backup inválido ou incompatível.');
    }

    final rawReports = data['reports'] as List<dynamic>? ?? [];
    return rawReports.map((item) {
      if (item is! Map<String, dynamic>) {
        return null;
      }
      final map = item;
      final stats = AnalysisStats.fromJson(map['stats'] as Map<String, dynamic>? ?? {});
      final verdictName = map['verdict'] as String? ?? 'inconclusive';
      final verdict = ScanVerdict.values.firstWhere(
        (v) => v.name == verdictName,
        orElse: () => ScanVerdict.inconclusive,
      );

      final dateVal = map['scan_date'];
      final DateTime scanDate;
      if (dateVal is String) {
        scanDate = DateTime.tryParse(dateVal) ?? DateTime.now();
      } else if (dateVal is int) {
        scanDate = DateTime.fromMillisecondsSinceEpoch(dateVal);
      } else {
        scanDate = DateTime.now();
      }

      // 1. Resultados individuais dos motores (v2)
      final Map<String, EngineResult> results = {};
      final rawResults = map['results'] as Map<String, dynamic>?;
      if (rawResults != null) {
        rawResults.forEach((key, val) {
          if (val is Map<String, dynamic>) {
            results[key] = EngineResult.fromJson(key, val);
          }
        });
      }

      // 2. Tags (v2)
      List<String> tags = const [];
      final rawTags = map['tags'] as List<dynamic>?;
      if (rawTags != null) {
        tags = rawTags.map((e) => e.toString()).toList();
      }

      // 3. Votos da comunidade (v2)
      TotalVotes? totalVotes;
      final rawVotes = map['total_votes'] as Map<String, dynamic>?;
      if (rawVotes != null) {
        totalVotes = TotalVotes.fromJson(rawVotes);
      }

      // 4. Extensão do arquivo (v2)
      final fileExtension = (map['file_extension'] as String?) ??
          (map['type_extension'] as String?);

      return ScanReport(
        id: map['id'] as String? ?? map['sha256'] as String? ?? '',
        sha256: map['sha256'] as String? ?? '',
        md5: map['md5'] as String?,
        sha1: map['sha1'] as String?,
        fileName: map['file_name'] as String? ?? 'Arquivo',
        fileSize: (map['file_size'] as num?)?.toInt() ?? 0,
        scanDate: scanDate,
        stats: stats,
        verdict: verdict,
        results: results,
        permalink: map['permalink'] as String?,
        mimeType: map['mime_type'] as String?,
        fileExtension: fileExtension,
        reputation: (map['reputation'] as num?)?.toInt(),
        tags: tags,
        totalVotes: totalVotes,
      );
    }).whereType<ScanReport>().toList();
  }
}
