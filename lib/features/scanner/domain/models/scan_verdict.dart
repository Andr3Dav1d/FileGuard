import 'analysis_stats.dart';

/// Classificação semântica do veredito de análise.
enum ScanVerdict {
  /// Pelo menos 1 motor detectou ameaça.
  malicious,

  /// Nenhum motor detectou malware direto, mas um ou mais classificaram como suspeito.
  suspicious,

  /// Motores analisaram e nenhuma ameaça conhecida foi detectada.
  /// NOTA: Não significa que o arquivo é garantidamente inofensivo.
  noDetections,

  /// Análise sem dados suficientes (falhas de motores ou formato não suportado).
  inconclusive,

  /// Arquivo enfileirado ou em processamento ativo.
  pending;

  /// Determina o veredito a partir das estatísticas dos motores antivírus.
  static ScanVerdict fromStats(AnalysisStats stats) {
    if (stats.malicious > 0) {
      return ScanVerdict.malicious;
    }
    if (stats.suspicious > 0) {
      return ScanVerdict.suspicious;
    }
    if ((stats.undetected + stats.harmless) > 0) {
      return ScanVerdict.noDetections;
    }
    return ScanVerdict.inconclusive;
  }
}
