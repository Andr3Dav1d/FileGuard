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
  Future<String> uploadFile({
    required List<int> bytes,
    required String fileName,
    void Function(int sent, int total)? onProgress,
  });

  /// Consulta o status e relatório de uma análise enfileirada.
  Future<ScanReport?> getAnalysis(String analysisId);
}
