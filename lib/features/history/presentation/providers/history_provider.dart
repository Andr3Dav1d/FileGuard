import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fileguard/features/history/data/datasources/scan_history_database.dart';
import 'package:fileguard/features/history/domain/repositories/scan_history_repository.dart';
import 'package:fileguard/features/scanner/domain/models/scan_report.dart';

/// Provedor do repositório SQLite de histórico.
final scanHistoryRepositoryProvider = Provider<ScanHistoryRepository>((ref) {
  return ScanHistoryDatabase();
});

/// Notifier que gerencia a lista reativa de análises históricas.
class HistoryNotifier extends AsyncNotifier<List<ScanReport>> {
  @override
  Future<List<ScanReport>> build() async {
    return _repository.getReports();
  }

  ScanHistoryRepository get _repository => ref.read(scanHistoryRepositoryProvider);

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.getReports());
  }

  Future<void> addReport(ScanReport report) async {
    await _repository.saveReport(report);
    await refresh();
  }

  Future<void> deleteReport(String id) async {
    await _repository.deleteReport(id);
    await refresh();
  }

  Future<void> clearAll() async {
    await _repository.clearHistory();
    await refresh();
  }
}

final historyNotifierProvider =
    AsyncNotifierProvider<HistoryNotifier, List<ScanReport>>(HistoryNotifier.new);
