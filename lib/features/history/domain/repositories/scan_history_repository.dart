import 'package:fileguard/features/scanner/domain/models/scan_report.dart';

/// Contrato para persistência e consulta do histórico local de análises.
abstract class ScanHistoryRepository {
  /// Retorna lista de relatórios ordenados por data decrescente.
  Future<List<ScanReport>> getReports();

  /// Salva ou atualiza um relatório no histórico local.
  Future<void> saveReport(ScanReport report);

  /// Exclui um registro individual pelo ID/Hash.
  Future<void> deleteReport(String id);

  /// Limpa todos os relatórios do histórico local.
  Future<void> clearHistory();
}
