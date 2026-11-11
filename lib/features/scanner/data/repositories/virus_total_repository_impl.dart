import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:fileguard/features/settings/domain/repositories/api_key_repository.dart';
import '../../domain/models/scan_report.dart';
import '../../domain/repositories/virus_total_repository.dart';

/// Implementação oficial do repositório VirusTotal consumindo a API v3.
class VirusTotalRepositoryImpl implements VirusTotalRepository {
  VirusTotalRepositoryImpl({
    required this.apiKeyRepository,
    http.Client? client,
    this.baseUrl = 'https://www.virustotal.com/api/v3',
  }) : _client = client ?? http.Client();

  final ApiKeyRepository apiKeyRepository;
  final http.Client _client;
  final String baseUrl;

  Future<String> _getRequiredApiKey() async {
    final key = await apiKeyRepository.getApiKey();
    if (key == null || key.trim().isEmpty) {
      throw const FormatException(
        'Nenhuma API Key configurada. Acesse as Configurações para inserir sua chave.',
      );
    }
    return key.trim();
  }

  @override
  Future<bool> validateApiKey(String apiKey) async {
    try {
      final uri = Uri.parse('$baseUrl/users/${apiKey.trim()}');
      final response = await _client.get(
        uri,
        headers: {
          'x-apikey': apiKey.trim(),
          'accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<HashLookupResult> getReportByHash(
    String sha256, {
    String? fileName,
    int? fileSize,
  }) async {
    final cleanHash = sha256.trim().toLowerCase();
    final String apiKey;
    try {
      apiKey = await _getRequiredApiKey();
    } catch (e) {
      return HashLookupError(e.toString());
    }

    try {
      final uri = Uri.parse('$baseUrl/files/$cleanHash');
      final response = await _client.get(
        uri,
        headers: {
          'x-apikey': apiKey,
          'accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body =
            jsonDecode(response.body) as Map<String, dynamic>;
        final report = ScanReport.fromVirusTotalJson(
          body,
          localFileName: fileName,
          localFileSize: fileSize,
        );
        return HashLookupFound(report);
      } else if (response.statusCode == 404) {
        // 404 indica apenas que o VirusTotal não possui registro deste hash
        return HashLookupNotFound(cleanHash);
      } else if (response.statusCode == 401) {
        return const HashLookupError(
          'API Key inválida ou sem permissão. Verifique nas Configurações.',
          statusCode: 401,
        );
      } else if (response.statusCode == 429) {
        return const HashLookupError(
          'Limite de requisições excedido na sua API Key.',
          statusCode: 429,
        );
      } else {
        return HashLookupError(
          'Erro ao consultar VirusTotal (código ${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return const HashLookupError('Sem conexão com a internet para consultar o hash.');
    } catch (e) {
      return HashLookupError('Falha de comunicação: $e');
    }
  }

  @override
  Future<String> uploadFile({
    required List<int> bytes,
    required String fileName,
    void Function(int sent, int total)? onProgress,
  }) async {
    final apiKey = await _getRequiredApiKey();
    final uri = Uri.parse('$baseUrl/files');

    final request = http.MultipartRequest('POST', uri);
    request.headers['x-apikey'] = apiKey;
    request.headers['accept'] = 'application/json';

    final multipartFile = http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: fileName,
    );
    request.files.add(multipartFile);

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      final analysisId = data?['id'] as String?;
      if (analysisId == null || analysisId.isEmpty) {
        throw const FormatException('Resposta de upload sem identificador de análise.');
      }
      return analysisId;
    } else if (response.statusCode == 401) {
      throw const HttpException('API Key inválida ou sem autorização para upload.');
    } else if (response.statusCode == 429) {
      throw const HttpException('Limite de cota de upload atingido.');
    } else {
      throw HttpException('Falha no upload do arquivo (HTTP ${response.statusCode}).');
    }
  }

  @override
  Future<ScanReport?> getAnalysis(String analysisId) async {
    final apiKey = await _getRequiredApiKey();
    final uri = Uri.parse('$baseUrl/analyses/$analysisId');

    final response = await _client.get(
      uri,
      headers: {
        'x-apikey': apiKey,
        'accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final attributes = data['attributes'] as Map<String, dynamic>? ?? {};
      final status = attributes['status'] as String? ?? 'queued';

      final meta = body['meta'] as Map<String, dynamic>? ?? {};
      final fileInfo = meta['file_info'] as Map<String, dynamic>? ?? {};
      final sha256 = fileInfo['sha256'] as String?;

      if (status == 'completed' && sha256 != null && sha256.isNotEmpty) {
        final fullLookup = await getReportByHash(sha256);
        if (fullLookup is HashLookupFound) {
          return fullLookup.report;
        }
      }
      return null;
    }
    return null;
  }
}
