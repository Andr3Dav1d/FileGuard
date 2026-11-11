import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/repositories/api_key_repository.dart';

/// Implementação de persistência segura da API Key utilizando o Android Keystore
/// via FlutterSecureStorage (EncryptedSharedPreferences no Android).
class SecureApiKeyStorage implements ApiKeyRepository {
  SecureApiKeyStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
            );

  final FlutterSecureStorage _storage;

  static const String _keyStorageName = 'fg_vt_api_key_secure';

  @override
  Future<String?> getApiKey() async {
    try {
      final key = await _storage.read(key: _keyStorageName);
      if (key == null || key.trim().isEmpty) {
        return null;
      }
      return key.trim();
    } catch (_) {
      // Falhas de leitura do Keystore não devem propagar segredos nem travar o app
      return null;
    }
  }

  @override
  Future<void> saveApiKey(String apiKey) async {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) {
      await deleteApiKey();
      return;
    }
    await _storage.write(key: _keyStorageName, value: trimmed);
  }

  @override
  Future<void> deleteApiKey() async {
    try {
      await _storage.delete(key: _keyStorageName);
    } catch (_) {
      // Ignora falhas se a chave já não existir
    }
  }

  @override
  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }
}
