import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:fileguard/features/settings/domain/repositories/api_key_repository.dart';
import '../../domain/models/scan_report.dart';
import '../../domain/repositories/virus_total_repository.dart';

/// Exceção disparada quando a API do VirusTotal retorna HTTP 429,
/// preservando o tempo sugerido no header `Retry-After`.
class RateLimitException implements HttpException {
  const RateLimitException(this.message, {this.retryAfter, this.uri});

  @override
  final String message;

  @override
  final Uri? uri;

  final Duration? retryAfter;

  @override
  String toString() => message;
}

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
          fallbackSha256: cleanHash,
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
        final retryAfterHeader = response.headers['retry-after'];
        final waitSeconds = retryAfterHeader != null ? int.tryParse(retryAfterHeader) : null;
        final waitMsg = waitSeconds != null ? ' Tente novamente em $waitSeconds s.' : '';
        return HashLookupError(
          'Limite de requisições excedido no VirusTotal.$waitMsg',
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
    String? filePath,
    List<int>? bytes,
    required String fileName,
    void Function(int sent, int total)? onProgress,
  }) async {
    final apiKey = await _getRequiredApiKey();
    final uri = Uri.parse('$baseUrl/files');

    final request = http.MultipartRequest('POST', uri);
    request.headers['x-apikey'] = apiKey;
    request.headers['accept'] = 'application/json';

    final http.MultipartFile multipartFile;
    if (filePath != null && filePath.isNotEmpty) {
      multipartFile = await http.MultipartFile.fromPath(
        'file',
        filePath,
        filename: fileName,
      );
    } else if (bytes != null) {
      multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      );
    } else {
      throw ArgumentError('É necessário fornecer filePath ou bytes para upload.');
    }
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
    } else if (response.statusCode == 413) {
      throw const HttpException('O arquivo excede o limite máximo suportado pelo VirusTotal (32 MB).');
    } else if (response.statusCode == 429) {
      throw const HttpException('Limite de cota de upload atingido.');
    } else {
      throw HttpException('Falha no upload do arquivo (HTTP ${response.statusCode}).');
    }
  }

  @override
  Future<ScanReport?> getAnalysis(
    String analysisId, {
    String? fileName,
    int? fileSize,
  }) async {
    final apiKey = await _getRequiredApiKey();
    final uri = Uri.parse('$baseUrl/analyses/$analysisId');

    final http.Response response;
    try {
      response = await _client.get(
        uri,
        headers: {
          'x-apikey': apiKey,
          'accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));
    } on SocketException {
      throw const SocketException('Sem conexão com a internet para consultar a análise.');
    } on TimeoutException {
      throw const SocketException('Tempo limite esgotado ao aguardar resposta do VirusTotal.');
    }

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final attributes = data['attributes'] as Map<String, dynamic>? ?? {};
      final status = attributes['status'] as String? ?? 'queued';

      if (status == 'completed') {
        // Constrói o ScanReport diretamente da resposta da análise, sem chamada redundante a /files/{id}
        return ScanReport.fromVirusTotalJson(
          body,
          localFileName: fileName,
          localFileSize: fileSize,
        );
      } else if (status == 'failed') {
        throw const HttpException('A análise falhou nos servidores do VirusTotal.');
      }
      // 'queued' ou 'in-progress'
      return null;
    } else if (response.statusCode == 401) {
      throw const HttpException('API Key inválida ou sem permissão. Verifique nas Configurações.');
    } else if (response.statusCode == 429) {
      final retryAfterHeader = response.headers['retry-after'];
      final waitSeconds = retryAfterHeader != null ? int.tryParse(retryAfterHeader) : null;
      throw RateLimitException(
        'Limite de requisições excedido na sua API Key do VirusTotal.',
        retryAfter: waitSeconds != null ? Duration(seconds: waitSeconds) : null,
      );
    } else if (response.statusCode == 404) {
      throw const HttpException('Análise não encontrada no VirusTotal.');
    } else {
      throw HttpException('Erro ao consultar status da análise (HTTP ${response.statusCode}).');
    }
  }

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
  }) async {
    Duration currentDelay = initialDelay;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      if (isCancelled?.call() == true) {
        return null;
      }

      final progressRatio = 0.70 + (attempt / maxAttempts) * 0.25;
      onProgress?.call(
        'Aguardando motores do VirusTotal ($attempt/$maxAttempts)...',
        progressRatio,
      );

      await Future.delayed(currentDelay);

      if (isCancelled?.call() == true) {
        return null;
      }

      try {
        final report = await getAnalysis(
          analysisId,
          fileName: fileName,
          fileSize: fileSize,
        );

        if (report != null) {
          // Concluído! Retorna o relatório imediatamente sem chamadas adicionais
          onProgress?.call('Análise concluída com sucesso!', 1.0);
          return report;
        }

        // Análise ainda em fila ou processamento ativo: incrementa delay com backoff progressivo
        currentDelay = Duration(
          milliseconds: (currentDelay.inMilliseconds * 1.5).round().clamp(
                initialDelay.inMilliseconds,
                maxDelay.inMilliseconds,
              ),
        );
      } on SocketException {
        // Erro temporário de conexão: notifica usuário e tenta novamente no próximo ciclo
        onProgress?.call(
          'Instabilidade temporária de rede. Retentando...',
          progressRatio,
        );
        currentDelay = maxDelay;
      } on RateLimitException catch (e) {
        // HTTP 429: respeita retry-after se presente, ou aguarda janela máxima
        onProgress?.call(
          'Limite temporário de requisições atingido. Aguardando...',
          progressRatio,
        );
        currentDelay = e.retryAfter ?? maxDelay;
      } on HttpException catch (e) {
        if (e.message.contains('Limite de requisições')) {
          // HTTP 429 legado: aguarda janela máxima de relaxamento antes de nova tentativa
          onProgress?.call(
            'Limite temporário de requisições atingido. Aguardando...',
            progressRatio,
          );
          currentDelay = maxDelay;
        } else if (e.message.contains('API Key') || e.message.contains('não encontrada') || e.message.contains('falhou')) {
          // Erro fatal não recuperável: propaga imediatamente
          rethrow;
        } else {
          currentDelay = maxDelay;
        }
      }
    }

    // Esgotou tentativas sem conclusão
    return null;
  }
}
