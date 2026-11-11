/// Contrato abstrato para persistência segura da API Key do VirusTotal.
abstract class ApiKeyRepository {
  /// Recupera a chave salva ou retorna null se não existir.
  Future<String?> getApiKey();

  /// Salva a chave com segurança no armazenamento protegido do dispositivo.
  Future<void> saveApiKey(String apiKey);

  /// Remove a chave com segurança do dispositivo.
  Future<void> deleteApiKey();

  /// Verifica se há uma chave salva.
  Future<bool> hasApiKey();
}
