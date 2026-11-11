import 'dart:io';
import 'package:crypto/crypto.dart';

/// Utilitário de cálculo de hash SHA-256 via streaming assíncrono.
/// Evita carregar arquivos inteiros na memória RAM do dispositivo.
class Sha256Calculator {
  const Sha256Calculator();

  /// Calcula o hash SHA-256 a partir de um fluxo binário ([Stream<List<int>>]).
  Future<String> calculateFromStream(Stream<List<int>> stream) async {
    final digest = await sha256.bind(stream).first;
    return digest.toString();
  }

  /// Calcula o hash SHA-256 a partir de uma instância de [File].
  Future<String> calculateFromFile(File file) async {
    if (!await file.exists()) {
      throw FileSystemException('Arquivo não encontrado no caminho especificado', file.path);
    }
    return calculateFromStream(file.openRead());
  }

  /// Calcula o hash SHA-256 a partir de uma lista de bytes em memória (útil para testes).
  String calculateFromBytes(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }
}
