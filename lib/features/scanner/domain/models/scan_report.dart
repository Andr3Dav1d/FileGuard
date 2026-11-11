import 'analysis_stats.dart';
import 'engine_result.dart';
import 'scan_verdict.dart';

/// Relatório consolidado de uma análise de arquivo no VirusTotal.
class ScanReport {
  const ScanReport({
    required this.id,
    required this.sha256,
    required this.fileName,
    required this.fileSize,
    required this.scanDate,
    required this.stats,
    required this.verdict,
    this.results = const {},
    this.permalink,
    this.mimeType,
  });

  final String id;
  final String sha256;
  final String fileName;
  final int fileSize;
  final DateTime scanDate;
  final AnalysisStats stats;
  final ScanVerdict verdict;
  final Map<String, EngineResult> results;
  final String? permalink;
  final String? mimeType;

  /// Retorna lista apenas de motores com detecções positivas (malicious ou suspicious).
  List<EngineResult> get threatEngines =>
      results.values.where((e) => e.isMalicious || e.isSuspicious).toList();

  factory ScanReport.fromVirusTotalJson(
    Map<String, dynamic> json, {
    String? localFileName,
    int? localFileSize,
  }) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final attributes = data['attributes'] as Map<String, dynamic>? ?? {};
    final id = (data['id'] as String?) ?? attributes['sha256'] as String? ?? '';
    final sha256 = (attributes['sha256'] as String?) ?? id;

    final stats = AnalysisStats.fromJson(
      attributes['last_analysis_stats'] as Map<String, dynamic>? ?? {},
    );

    final rawResults =
        attributes['last_analysis_results'] as Map<String, dynamic>? ?? {};
    final Map<String, EngineResult> parsedResults = {};
    rawResults.forEach((key, val) {
      if (val is Map<String, dynamic>) {
        parsedResults[key] = EngineResult.fromJson(key, val);
      }
    });

    final scanDateEpoch =
        (attributes['last_analysis_date'] as num?)?.toInt() ??
        (attributes['date'] as num?)?.toInt();
    final scanDate = scanDateEpoch != null
        ? DateTime.fromMillisecondsSinceEpoch(scanDateEpoch * 1000)
        : DateTime.now();

    final meaningName = (attributes['meaningful_name'] as String?) ??
        (attributes['names'] as List?)?.firstOrNull as String? ??
        localFileName ??
        'Arquivo sem nome';

    final size = (attributes['size'] as num?)?.toInt() ?? localFileSize ?? 0;
    final mime = attributes['type_description'] as String? ??
        attributes['magic'] as String?;

    final verdict = ScanVerdict.fromStats(stats);

    return ScanReport(
      id: id,
      sha256: sha256,
      fileName: meaningName,
      fileSize: size,
      scanDate: scanDate,
      stats: stats,
      verdict: verdict,
      results: parsedResults,
      permalink: 'https://www.virustotal.com/gui/file/$sha256',
      mimeType: mime,
    );
  }
}
