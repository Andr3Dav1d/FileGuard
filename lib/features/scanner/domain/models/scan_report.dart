import 'analysis_stats.dart';
import 'engine_result.dart';
import 'scan_verdict.dart';
import 'total_votes.dart';

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
    this.md5,
    this.sha1,
    this.reputation,
    this.tags = const [],
    this.totalVotes,
    this.fileExtension,
  });

  final String id;
  final String sha256;
  final String? md5;
  final String? sha1;
  final String fileName;
  final int fileSize;
  final DateTime scanDate;
  final AnalysisStats stats;
  final ScanVerdict verdict;
  final Map<String, EngineResult> results;
  final String? permalink;
  final String? mimeType;
  final String? fileExtension;
  final int? reputation;
  final List<String> tags;
  final TotalVotes? totalVotes;

  /// Retorna lista de motores com detecções positivas (malicious ou suspicious).
  List<EngineResult> get threatEngines =>
      results.values.where((e) => e.isMalicious || e.isSuspicious).toList();

  /// Retorna lista de motores com veredito explicitamente malicioso.
  List<EngineResult> get maliciousEngines =>
      results.values.where((e) => e.isMalicious).toList();

  /// Retorna lista de motores com veredito suspeito.
  List<EngineResult> get suspiciousEngines =>
      results.values.where((e) => e.isSuspicious).toList();

  /// Retorna lista de motores sem detecção de ameaça ou inofensivos.
  List<EngineResult> get cleanEngines =>
      results.values.where((e) => e.isUndetected || e.isHarmless).toList();

  /// Constrói um [ScanReport] a partir de respostas da API v3 do VirusTotal.
  ///
  /// Suporta tanto o endpoint de arquivo (`/files/{id}`) quanto o de análise (`/analyses/{id}`).
  factory ScanReport.fromVirusTotalJson(
    Map<String, dynamic> json, {
    String? localFileName,
    int? localFileSize,
    String? fallbackSha256,
  }) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final attributes = data['attributes'] as Map<String, dynamic>? ?? {};
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final fileInfo = meta['file_info'] as Map<String, dynamic>? ?? {};

    // 1. Identificador e Hashes
    // Em /files/{id}: vêm em attributes ou em data.id
    // Em /analyses/{id}: id da análise vem em data.id (base64), mas hashes do arquivo vêm em meta.file_info
    final dataType = data['type'] as String?;
    final isAnalysisType = dataType == 'analysis';
    final dataId = data['id'] as String?;

    final sha256 = (attributes['sha256'] as String?) ??
        (fileInfo['sha256'] as String?) ??
        (!isAnalysisType ? dataId : null) ??
        fallbackSha256 ??
        '';
    final id = (data['id'] as String?) ?? (sha256.isNotEmpty ? sha256 : '');
    final md5 = (attributes['md5'] as String?) ?? (fileInfo['md5'] as String?);
    final sha1 = (attributes['sha1'] as String?) ?? (fileInfo['sha1'] as String?);

    // 2. Estatísticas da Análise
    // Em /files/{id}: 'last_analysis_stats'
    // Em /analyses/{id}: 'stats'
    final rawStats = (attributes['last_analysis_stats'] as Map<String, dynamic>?) ??
        (attributes['stats'] as Map<String, dynamic>?) ??
        {};
    final stats = AnalysisStats.fromJson(rawStats);

    // 3. Resultados Individuais dos Motores
    // Em /files/{id}: 'last_analysis_results'
    // Em /analyses/{id}: 'results'
    final rawResults = (attributes['last_analysis_results'] as Map<String, dynamic>?) ??
        (attributes['results'] as Map<String, dynamic>?) ??
        {};
    final Map<String, EngineResult> parsedResults = {};
    rawResults.forEach((key, val) {
      if (val is Map<String, dynamic>) {
        parsedResults[key] = EngineResult.fromJson(key, val);
      }
    });

    // 4. Data da Análise
    // Em /files/{id}: 'last_analysis_date'
    // Em /analyses/{id}: 'date'
    final scanDateEpoch = (attributes['last_analysis_date'] as num?)?.toInt() ??
        (attributes['date'] as num?)?.toInt();
    final scanDate = scanDateEpoch != null
        ? DateTime.fromMillisecondsSinceEpoch(scanDateEpoch * 1000)
        : DateTime.now();

    // 5. Nome do Arquivo
    final meaningfulName = (attributes['meaningful_name'] as String?) ??
        (attributes['names'] as List?)?.firstOrNull as String? ??
        localFileName ??
        'Arquivo sem nome';

    // 6. Tamanho do Arquivo
    final size = (attributes['size'] as num?)?.toInt() ??
        (fileInfo['size'] as num?)?.toInt() ??
        localFileSize ??
        0;

    // 7. MIME Type, Descrição e Extensão
    final mime = (attributes['type_description'] as String?) ??
        (attributes['magic'] as String?);
    final fileExtension = attributes['type_extension'] as String?;

    // 8. Reputação e Tags
    final reputation = (attributes['reputation'] as num?)?.toInt();
    final rawTags = attributes['tags'] as List<dynamic>?;
    final List<String> tags = rawTags != null
        ? rawTags.map((e) => e.toString()).toList()
        : const [];

    // 9. Votos da Comunidade
    final rawVotes = attributes['total_votes'] as Map<String, dynamic>?;
    final totalVotes = rawVotes != null ? TotalVotes.fromJson(rawVotes) : null;

    // 10. Veredito consolidado
    final verdict = ScanVerdict.fromStats(stats);

    return ScanReport(
      id: id,
      sha256: sha256,
      md5: md5,
      sha1: sha1,
      fileName: meaningfulName,
      fileSize: size,
      scanDate: scanDate,
      stats: stats,
      verdict: verdict,
      results: parsedResults,
      permalink: sha256.isNotEmpty ? 'https://www.virustotal.com/gui/file/$sha256' : null,
      mimeType: mime,
      fileExtension: fileExtension,
      reputation: reputation,
      tags: tags,
      totalVotes: totalVotes,
    );
  }

  /// Serialização para persistência ou cache JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'sha256': sha256,
    if (md5 != null) 'md5': md5,
    if (sha1 != null) 'sha1': sha1,
    'file_name': fileName,
    'file_size': fileSize,
    'scan_date': scanDate.millisecondsSinceEpoch,
    'stats': stats.toJson(),
    'verdict': verdict.name,
    'results': results.map((key, val) => MapEntry(key, val.toJson())),
    if (permalink != null) 'permalink': permalink,
    if (mimeType != null) 'mime_type': mimeType,
    if (fileExtension != null) 'type_extension': fileExtension,
    if (reputation != null) 'reputation': reputation,
    'tags': tags,
    if (totalVotes != null) 'total_votes': totalVotes!.toJson(),
  };

  /// Desserialização a partir do formato JSON serializado por [toJson].
  factory ScanReport.fromJson(Map<String, dynamic> json) {
    final rawStats = json['stats'] as Map<String, dynamic>? ?? {};
    final stats = AnalysisStats.fromJson(rawStats);

    final verdictName = json['verdict'] as String? ?? 'inconclusive';
    final verdict = ScanVerdict.values.firstWhere(
      (v) => v.name == verdictName,
      orElse: () => ScanVerdict.inconclusive,
    );

    final rawResults = json['results'] as Map<String, dynamic>? ?? {};
    final Map<String, EngineResult> parsedResults = {};
    rawResults.forEach((key, val) {
      if (val is Map<String, dynamic>) {
        parsedResults[key] = EngineResult.fromJson(key, val);
      }
    });

    final scanDateVal = json['scan_date'];
    final DateTime scanDate;
    if (scanDateVal is int) {
      scanDate = DateTime.fromMillisecondsSinceEpoch(scanDateVal);
    } else if (scanDateVal is String) {
      scanDate = DateTime.tryParse(scanDateVal) ?? DateTime.now();
    } else {
      scanDate = DateTime.now();
    }

    final rawTags = json['tags'] as List<dynamic>?;
    final List<String> tags = rawTags != null
        ? rawTags.map((e) => e.toString()).toList()
        : const [];

    final rawVotes = json['total_votes'] as Map<String, dynamic>?;
    final totalVotes = rawVotes != null ? TotalVotes.fromJson(rawVotes) : null;

    return ScanReport(
      id: json['id'] as String? ?? '',
      sha256: json['sha256'] as String? ?? '',
      md5: json['md5'] as String?,
      sha1: json['sha1'] as String?,
      fileName: json['file_name'] as String? ?? 'Arquivo',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      scanDate: scanDate,
      stats: stats,
      verdict: verdict,
      results: parsedResults,
      permalink: json['permalink'] as String?,
      mimeType: json['mime_type'] as String?,
      fileExtension: json['type_extension'] as String?,
      reputation: (json['reputation'] as num?)?.toInt(),
      tags: tags,
      totalVotes: totalVotes,
    );
  }
}
