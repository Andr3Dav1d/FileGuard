import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fileguard/features/history/presentation/providers/history_provider.dart';
import 'package:fileguard/features/scanner/data/repositories/virus_total_repository_impl.dart';
import 'package:fileguard/features/scanner/data/services/file_picker_service.dart';
import 'package:fileguard/features/scanner/domain/models/scan_report.dart';
import 'package:fileguard/features/scanner/domain/models/selected_file_info.dart';
import 'package:fileguard/features/scanner/domain/repositories/virus_total_repository.dart';
import 'package:fileguard/features/settings/presentation/providers/api_key_provider.dart';

/// Limite máximo em bytes suportado pelo endpoint padrão de upload do VirusTotal v3 (32 MB).
const int _maxUploadSizeBytes = 32 * 1024 * 1024;

/// Provedor do repositório VirusTotal.
final virusTotalRepositoryProvider = Provider<VirusTotalRepository>((ref) {
  final apiKeyRepo = ref.read(apiKeyRepositoryProvider);
  return VirusTotalRepositoryImpl(apiKeyRepository: apiKeyRepo);
});

/// Provedor do serviço de seleção de arquivos SAF.
final filePickerServiceProvider = Provider<FilePickerService>((ref) {
  return FilePickerService();
});

/// Estados do fluxo de análise no Analisador.
enum ScannerStep {
  idle,
  hashing,
  queryingHash,
  promptConsent,
  uploading,
  analyzing,
  queued,
  completed,
  error,
}

class ScannerState {
  const ScannerState({
    this.step = ScannerStep.idle,
    this.selectedFile,
    this.report,
    this.uploadProgress,
    this.statusText,
    this.errorMessage,
    this.pendingAnalysisId,
  });

  final ScannerStep step;
  final SelectedFileInfo? selectedFile;
  final ScanReport? report;
  final double? uploadProgress;
  final String? statusText;
  final String? errorMessage;
  final String? pendingAnalysisId;

  bool get isLoading =>
      step == ScannerStep.hashing ||
      step == ScannerStep.queryingHash ||
      step == ScannerStep.uploading ||
      step == ScannerStep.analyzing;

  ScannerState copyWith({
    ScannerStep? step,
    SelectedFileInfo? selectedFile,
    ScanReport? report,
    double? uploadProgress,
    String? statusText,
    String? errorMessage,
    String? pendingAnalysisId,
    bool clearReport = false,
    bool clearPendingAnalysisId = false,
  }) {
    return ScannerState(
      step: step ?? this.step,
      selectedFile: selectedFile ?? this.selectedFile,
      report: clearReport ? null : (report ?? this.report),
      uploadProgress: uploadProgress ?? this.uploadProgress,
      statusText: statusText ?? this.statusText,
      errorMessage: errorMessage ?? this.errorMessage,
      pendingAnalysisId: clearPendingAnalysisId
          ? null
          : (pendingAnalysisId ?? this.pendingAnalysisId),
    );
  }
}

class ScannerNotifier extends Notifier<ScannerState> {
  @override
  ScannerState build() => const ScannerState();

  FilePickerService get _pickerService => ref.read(filePickerServiceProvider);
  VirusTotalRepository get _vtRepository => ref.read(virusTotalRepositoryProvider);

  /// Inicia o fluxo: seleciona arquivo via SAF, calcula hash em stream e consulta VT.
  Future<void> pickAndScan() async {
    // 1. Verifica se há chave de API cadastrada
    final apiKeyState = ref.read(apiKeyNotifierProvider);
    if (!apiKeyState.hasKey) {
      state = const ScannerState(
        step: ScannerStep.error,
        errorMessage: 'Configure sua API Key nas Configurações antes de realizar análises.',
      );
      return;
    }

    state = const ScannerState(
      step: ScannerStep.hashing,
      statusText: 'Selecionando arquivo...',
    );

    try {
      final fileInfo = await _pickerService.pickAndProcessFile();
      if (fileInfo == null) {
        // Usuário cancelou o seletor nativo
        state = const ScannerState(step: ScannerStep.idle);
        return;
      }

      state = state.copyWith(
        step: ScannerStep.queryingHash,
        selectedFile: fileInfo,
        statusText: 'Consultando hash SHA-256 no VirusTotal...',
      );

      final lookupResult = await _vtRepository.getReportByHash(
        fileInfo.sha256!,
        fileName: fileInfo.name,
        fileSize: fileInfo.size,
      );

      if (lookupResult is HashLookupFound) {
        state = state.copyWith(
          step: ScannerStep.completed,
          report: lookupResult.report,
          statusText: 'Relatório recuperado com sucesso.',
        );
        // Persiste no histórico local
        await ref.read(historyNotifierProvider.notifier).addReport(lookupResult.report);
      } else if (lookupResult is HashLookupNotFound) {
        // 404: Hash não encontrado.
        if (fileInfo.size > _maxUploadSizeBytes) {
          state = state.copyWith(
            step: ScannerStep.error,
            errorMessage:
                'O arquivo selecionado (${fileInfo.formattedSize}) excede o limite máximo de 32 MB '
                'suportado pela API pública do VirusTotal para uploads.',
          );
          return;
        }

        // Exibe solicitação de consentimento para upload.
        state = state.copyWith(
          step: ScannerStep.promptConsent,
          statusText: 'Arquivo não catalogado no VirusTotal.',
        );
      } else if (lookupResult is HashLookupError) {
        state = state.copyWith(
          step: ScannerStep.error,
          errorMessage: lookupResult.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        step: ScannerStep.error,
        errorMessage: 'Erro durante o processamento do arquivo: $e',
      );
    }
  }

  /// Usuário confirmou o consentimento de upload.
  Future<void> confirmUpload() async {
    final file = state.selectedFile;
    if (file == null || file.path.isEmpty) {
      state = state.copyWith(
        step: ScannerStep.error,
        errorMessage: 'Caminho do arquivo inacessível para upload.',
      );
      return;
    }

    if (file.size > _maxUploadSizeBytes) {
      state = state.copyWith(
        step: ScannerStep.error,
        errorMessage:
            'O arquivo selecionado (${file.formattedSize}) excede o limite de 32 MB para envio ao VirusTotal.',
      );
      return;
    }

    state = state.copyWith(
      step: ScannerStep.uploading,
      statusText: 'Enviando arquivo ao VirusTotal...',
      uploadProgress: 0.3,
    );

    try {
      state = state.copyWith(uploadProgress: 0.5);

      final analysisId = await _vtRepository.uploadFile(
        filePath: file.path,
        fileName: file.name,
      );

      state = state.copyWith(
        step: ScannerStep.analyzing,
        statusText: 'Análise enfileirada no VirusTotal. Aguardando motores...',
        uploadProgress: 0.7,
      );

      // Polling progressivo com backoff exponencial e tratamento de cota
      final completedReport = await _vtRepository.pollAnalysis(
        analysisId: analysisId,
        fileName: file.name,
        fileSize: file.size,
        onProgress: (statusMessage, progress) {
          state = state.copyWith(
            statusText: statusMessage,
            uploadProgress: progress,
          );
        },
      );

      if (completedReport != null) {
        state = state.copyWith(
          step: ScannerStep.completed,
          report: completedReport,
          uploadProgress: 1.0,
          statusText: 'Análise concluída com sucesso!',
          clearPendingAnalysisId: true,
        );
        await ref.read(historyNotifierProvider.notifier).addReport(completedReport);
      } else {
        // Análise ainda em processamento assíncrono na fila do VT: preserva estado e ID
        state = state.copyWith(
          step: ScannerStep.queued,
          pendingAnalysisId: analysisId,
          uploadProgress: null,
          statusText: 'Análise enfileirada no VirusTotal. Motores ainda processando.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        step: ScannerStep.error,
        errorMessage: 'Falha no envio do arquivo: $e',
      );
    }
  }

  /// Reconsulta o status de uma análise que permaneceu na fila do VirusTotal.
  Future<void> recheckPendingAnalysis() async {
    final analysisId = state.pendingAnalysisId;
    if (analysisId == null || analysisId.isEmpty) return;

    state = state.copyWith(
      step: ScannerStep.analyzing,
      statusText: 'Consultando status dos motores no VirusTotal...',
      uploadProgress: 0.7,
    );

    try {
      final completedReport = await _vtRepository.pollAnalysis(
        analysisId: analysisId,
        fileName: state.selectedFile?.name,
        fileSize: state.selectedFile?.size,
        onProgress: (statusMessage, progress) {
          state = state.copyWith(
            statusText: statusMessage,
            uploadProgress: progress,
          );
        },
      );

      if (completedReport != null) {
        state = state.copyWith(
          step: ScannerStep.completed,
          report: completedReport,
          uploadProgress: 1.0,
          statusText: 'Análise concluída com sucesso!',
          clearPendingAnalysisId: true,
        );
        await ref.read(historyNotifierProvider.notifier).addReport(completedReport);
      } else {
        state = state.copyWith(
          step: ScannerStep.queued,
          uploadProgress: null,
          statusText: 'O arquivo ainda está em processamento na fila do VirusTotal.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        step: ScannerStep.error,
        errorMessage: 'Falha ao consultar status da análise: $e',
      );
    }
  }

  /// Usuário cancelou o consentimento de upload.
  void cancelConsent() {
    state = const ScannerState(
      step: ScannerStep.idle,
      statusText: 'Envio cancelado pelo usuário.',
    );
  }

  /// Reinicia para nova análise.
  void reset() {
    state = const ScannerState(step: ScannerStep.idle);
  }
}

final scannerNotifierProvider =
    NotifierProvider<ScannerNotifier, ScannerState>(ScannerNotifier.new);
