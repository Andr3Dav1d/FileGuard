import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:fileguard/features/settings/domain/models/api_key_status.dart';

/// Cliente HTTP dedicado para comunicação com a API v3 do VirusTotal.
/// Nunca expõe chaves em logs ou exceções.
class VirusTotalApiClient {
  VirusTotalApiClient({
    http.Client? client,
    this.baseUrl = 'https://www.virustotal.com/api/v3',
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  /// Valida uma API Key consultando o endpoint de usuário do VirusTotal.
  Future<ApiKeyStatus> validateApiKey(String apiKey) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      return ApiKeyStatus.notConfigured;
    }

    try {
      final uri = Uri.parse('$baseUrl/users/$cleanKey');
      final response = await _client
          .get(
            uri,
            headers: {
              'x-apikey': cleanKey,
              'accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      switch (response.statusCode) {
        case 200:
          return ApiKeyStatus.valid;
        case 401:
          return ApiKeyStatus.invalid;
        case 429:
          return ApiKeyStatus.quotaExceeded;
        default:
          return ApiKeyStatus.temporaryError;
      }
    } on SocketException {
      return ApiKeyStatus.networkError;
    } on TimeoutException {
      return ApiKeyStatus.networkError;
    } catch (_) {
      return ApiKeyStatus.temporaryError;
    }
  }

  void close() {
    _client.close();
  }
}
