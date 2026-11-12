import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fileguard/features/scanner/domain/models/scan_report.dart';
import 'package:fileguard/features/scanner/domain/models/selected_file_info.dart';
import 'package:fileguard/features/scanner/domain/repositories/virus_total_repository.dart';
import 'package:fileguard/features/scanner/data/services/file_picker_service.dart';
import 'package:fileguard/features/scanner/presentation/providers/scanner_provider.dart';
import 'package:fileguard/features/settings/domain/repositories/api_key_repository.dart';
import 'package:fileguard/features/settings/presentation/providers/api_key_provider.dart';

class FakeApiKeyRepository implements ApiKeyRepository {
  @override
  Future<String?> getApiKey() async => 'test_key';
  @override
  Future<void> saveApiKey(String apiKey) async {}
  @override
  Future<void> deleteApiKey() async {}
  @override
  Future<bool> hasApiKey() async => true;
}

class FakeFilePickerService implements FilePickerService {
  FakeFilePickerService(this.fileInfo);
  final SelectedFileInfo? fileInfo;

  @override
  Future<SelectedFileInfo?> pickAndProcessFile() async => fileInfo;
}

class FakeVirusTotalRepository implements VirusTotalRepository {
  @override
  Future<bool> validateApiKey(String apiKey) async => true;

  @override
  Future<HashLookupResult> getReportByHash(
    String sha256, {
    String? fileName,
    int? fileSize,
  }) async {
    return HashLookupNotFound(sha256);
  }

  @override
  Future<String> uploadFile({
    String? filePath,
    List<int>? bytes,
    required String fileName,
    void Function(int sent, int total)? onProgress,
  }) async => 'mock_analysis_id';

  @override
  Future<ScanReport?> getAnalysis(
    String analysisId, {
    String? fileName,
    int? fileSize,
  }) async => null;

  @override
  Future<ScanReport?> pollAnalysis({
    required String analysisId,
    String? fileName,
    int? fileSize,
    int maxAttempts = 5,
    Duration initialDelay = const Duration(seconds: 4),
    Duration maxDelay = const Duration(seconds: 16),
    void Function(String statusMessage, double? progress)? onProgress,
    bool Function()? isCancelled,
  }) async => null;
}

void main() {
  group('ScannerNotifier 32 MB File Size Limit Tests', () {
    test('pickAndScan rejeita arquivos maiores que 32 MB sem exibir prompt de upload', () async {
      final bigFile = SelectedFileInfo(
        name: 'huge_installer.iso',
        path: '/tmp/huge_installer.iso',
        size: 35 * 1024 * 1024, // 35 MB (> 32 MB)
        sha256: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        mimeType: 'application/octet-stream',
      );

      final container = ProviderContainer(
        overrides: [
          apiKeyRepositoryProvider.overrideWithValue(FakeApiKeyRepository()),
          filePickerServiceProvider.overrideWithValue(FakeFilePickerService(bigFile)),
          virusTotalRepositoryProvider.overrideWithValue(FakeVirusTotalRepository()),
        ],
      );
      addTearDown(container.dispose);

      // Garante que o estado de API key está carregado com chave
      await container.read(apiKeyNotifierProvider.notifier).loadApiKey();

      final notifier = container.read(scannerNotifierProvider.notifier);
      await notifier.pickAndScan();

      final state = container.read(scannerNotifierProvider);
      expect(state.step, equals(ScannerStep.error));
      expect(state.errorMessage, contains('32 MB'));
    });

    test('pickAndScan exibe promptConsent para arquivos de até 32 MB', () async {
      final normalFile = SelectedFileInfo(
        name: 'small_binary.exe',
        path: '/tmp/small_binary.exe',
        size: 15 * 1024 * 1024, // 15 MB (< 32 MB)
        sha256: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        mimeType: 'application/x-dosexec',
      );

      final container = ProviderContainer(
        overrides: [
          apiKeyRepositoryProvider.overrideWithValue(FakeApiKeyRepository()),
          filePickerServiceProvider.overrideWithValue(FakeFilePickerService(normalFile)),
          virusTotalRepositoryProvider.overrideWithValue(FakeVirusTotalRepository()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(apiKeyNotifierProvider.notifier).loadApiKey();

      final notifier = container.read(scannerNotifierProvider.notifier);
      await notifier.pickAndScan();

      final state = container.read(scannerNotifierProvider);
      expect(state.step, equals(ScannerStep.promptConsent));
    });

    test('confirmUpload define step queued e preserva pendingAnalysisId quando polling expira', () async {
      final file = SelectedFileInfo(
        name: 'test_binary.bin',
        path: '/tmp/test_binary.bin',
        size: 1024,
        sha256: 'abc123sha256',
        mimeType: 'application/octet-stream',
      );

      final container = ProviderContainer(
        overrides: [
          apiKeyRepositoryProvider.overrideWithValue(FakeApiKeyRepository()),
          filePickerServiceProvider.overrideWithValue(FakeFilePickerService(file)),
          virusTotalRepositoryProvider.overrideWithValue(FakeVirusTotalRepository()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(apiKeyNotifierProvider.notifier).loadApiKey();

      final notifier = container.read(scannerNotifierProvider.notifier);
      await notifier.pickAndScan();
      expect(container.read(scannerNotifierProvider).step, equals(ScannerStep.promptConsent));

      await notifier.confirmUpload();

      final state = container.read(scannerNotifierProvider);
      expect(state.step, equals(ScannerStep.queued));
      expect(state.pendingAnalysisId, equals('mock_analysis_id'));
    });
  });
}
