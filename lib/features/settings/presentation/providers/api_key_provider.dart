import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/secure_api_key_storage.dart';
import '../../domain/models/api_key_status.dart';
import '../../domain/repositories/api_key_repository.dart';
import '../../../scanner/data/datasources/virus_total_api_client.dart';

/// Provedor do repositório de armazenamento seguro.
final apiKeyRepositoryProvider = Provider<ApiKeyRepository>((ref) {
  return SecureApiKeyStorage();
});

/// Provedor do cliente HTTP do VirusTotal.
final virusTotalApiClientProvider = Provider<VirusTotalApiClient>((ref) {
  final client = VirusTotalApiClient();
  ref.onDispose(client.close);
  return client;
});

/// Estado da configuração da API Key.
class ApiKeyState {
  const ApiKeyState({
    this.apiKey,
    this.status = ApiKeyStatus.notConfigured,
    this.isLoading = false,
    this.statusMessage,
  });

  final String? apiKey;
  final ApiKeyStatus status;
  final bool isLoading;
  final String? statusMessage;

  bool get hasKey => apiKey != null && apiKey!.isNotEmpty;

  /// Retorna a chave mascarada para exibição segura na UI.
  String get maskedKey {
    if (apiKey == null || apiKey!.isEmpty) return '';
    if (apiKey!.length <= 8) return '••••••••';
    final start = apiKey!.substring(0, 4);
    final end = apiKey!.substring(apiKey!.length - 4);
    return '$start••••••••$end';
  }

  ApiKeyState copyWith({
    String? apiKey,
    ApiKeyStatus? status,
    bool? isLoading,
    String? statusMessage,
    bool clearKey = false,
  }) {
    return ApiKeyState(
      apiKey: clearKey ? null : (apiKey ?? this.apiKey),
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

/// Gerenciador de estado do ciclo de vida da API Key.
class ApiKeyNotifier extends Notifier<ApiKeyState> {
  @override
  ApiKeyState build() {
    // Carrega a chave salva de forma assíncrona na inicialização
    Future.microtask(loadApiKey);
    return const ApiKeyState(isLoading: false);
  }

  ApiKeyRepository get _repository => ref.read(apiKeyRepositoryProvider);
  VirusTotalApiClient get _apiClient => ref.read(virusTotalApiClientProvider);

  /// Carrega a chave gravada no armazenamento seguro.
  Future<void> loadApiKey() async {
    try {
      final savedKey = await _repository.getApiKey();

      if (savedKey == null || savedKey.isEmpty) {
        state = const ApiKeyState(
          apiKey: null,
          status: ApiKeyStatus.notConfigured,
          isLoading: false,
        );
        return;
      }

      state = ApiKeyState(
        apiKey: savedKey,
        status: ApiKeyStatus.valid, // Presume válida localmente até revalidação
        isLoading: false,
      );
    } catch (_) {
      state = const ApiKeyState(
        apiKey: null,
        status: ApiKeyStatus.notConfigured,
        isLoading: false,
      );
    }
  }

  /// Valida e salva uma nova API Key fornecida pelo usuário.
  Future<bool> saveAndValidate(String newKey) async {
    final cleanKey = newKey.trim();
    if (cleanKey.isEmpty) {
      await deleteKey();
      return true;
    }

    state = state.copyWith(
      isLoading: true,
      status: ApiKeyStatus.validating,
      statusMessage: 'Validando chave com o VirusTotal...',
    );

    final validationStatus = await _apiClient.validateApiKey(cleanKey);

    if (validationStatus == ApiKeyStatus.valid) {
      await _repository.saveApiKey(cleanKey);
      state = ApiKeyState(
        apiKey: cleanKey,
        status: ApiKeyStatus.valid,
        isLoading: false,
        statusMessage: 'API Key validada e salva com segurança!',
      );
      return true;
    } else {
      state = state.copyWith(
        status: validationStatus,
        isLoading: false,
        statusMessage: validationStatus.description,
      );
      return false;
    }
  }

  /// Revalida a chave atualmente armazenada.
  Future<void> revalidateCurrentKey() async {
    final currentKey = state.apiKey;
    if (currentKey == null || currentKey.isEmpty) {
      state = const ApiKeyState(status: ApiKeyStatus.notConfigured);
      return;
    }

    state = state.copyWith(
      isLoading: true,
      status: ApiKeyStatus.validating,
      statusMessage: 'Testando conexão e limites da chave...',
    );

    final validationStatus = await _apiClient.validateApiKey(currentKey);

    state = state.copyWith(
      status: validationStatus,
      isLoading: false,
      statusMessage: validationStatus == ApiKeyStatus.valid
          ? 'Conexão ativa e chave operacional!'
          : validationStatus.description,
    );
  }

  /// Remove a chave com segurança do dispositivo.
  Future<void> deleteKey() async {
    state = state.copyWith(isLoading: true);
    await _repository.deleteApiKey();
    state = const ApiKeyState(
      apiKey: null,
      status: ApiKeyStatus.notConfigured,
      isLoading: false,
      statusMessage: 'API Key removida do dispositivo.',
    );
  }
}

/// Provedor global do gerenciador da API Key.
final apiKeyNotifierProvider =
    NotifierProvider<ApiKeyNotifier, ApiKeyState>(ApiKeyNotifier.new);
