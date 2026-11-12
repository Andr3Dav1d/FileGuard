import '../models/scan_report.dart';

/// Resultado da consulta de hash
sealed class HashLookupResult {
  const HashLookupResult();
}

class HashLookupFound extends HashLookupResult {
  const HashLookupFound(this.report);
  final ScanReport report;
}

class HashLookupNotFound extends HashLookupResult {
  const HashLookupNotFound(this.sha256);
  final String sha256;
}

class HashLookupError extends HashLookupResult {
  const HashLookupError(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
}

/// Contrato para comunicação com o VirusTotal.
abstract class VirusTotalRepository {
  /// Valida uma API Key com a API do VirusTotal.
  Future<bool> validateApiKey(String apiKey);

  /// Consulta um relatório a partir do hash SHA-256 do arquivo.
  Future<HashLookupResult> getReportByHash(
    String sha256, {
    String? fileName,
    int? fileSize,
  });

  /// Envia um arquivo para análise no VirusTotal após consentimento explícito.
  /// Pode receber o caminho local [filePath] para transmissão em stream
  /// ou bytes em memória [bytes] como fallback.
  Future<String> uploadFile({
    String? filePath,
    List<int>? bytes,
    required String fileName,
    void Function(int sent, int total)? onProgress,
  });

  /// Consulta o status e relatório de uma análise enfileirada.
  /// Constrói o [ScanReport] diretamente a partir de `/analyses/{id}` quando concluída.
  Future<ScanReport?> getAnalysis(
    String analysisId, {
    String? fileName,
    int? fileSize,
  });

  /// Realiza polling progressivo inteligente até a conclusão da análise ou esgotamento de tentativas.
  Future<ScanReport?> pollAnalysis({
    required String analysisId,
    String? fileName,
    int? fileSize,
    int maxAttempts = 5,
    Duration initialDelay = const Duration(seconds: 4),
    Duration maxDelay = const Duration(seconds: 16),
    void Function(String statusMessage, double? progress)? onProgress,
    bool Function()? isCancelled,
  });
}
