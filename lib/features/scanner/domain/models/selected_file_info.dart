import 'package:fileguard/core/utils/file_size_formatter.dart';

/// Informações e metadados de um arquivo selecionado para análise.
class SelectedFileInfo {
  const SelectedFileInfo({
    required this.name,
    required this.size,
    required this.path,
    this.mimeType,
    this.sha256,
  });

  /// Nome do arquivo com extensão.
  final String name;

  /// Tamanho em bytes.
  final int size;

  /// Caminho ou URI do arquivo no dispositivo.
  final String path;

  /// Tipo MIME detectado.
  final String? mimeType;

  /// Hash SHA-256 calculado do conteúdo.
  final String? sha256;

  /// Indica se o arquivo é um pacote Android (APK).
  bool get isApk =>
      name.toLowerCase().endsWith('.apk') ||
      mimeType == 'application/vnd.android.package-archive';

  /// Retorna tamanho formatado legível (ex: 2.4 MB).
  String get formattedSize => FileSizeFormatter.format(size);

  SelectedFileInfo copyWith({
    String? name,
    int? size,
    String? path,
    String? mimeType,
    String? sha256,
  }) {
    return SelectedFileInfo(
      name: name ?? this.name,
      size: size ?? this.size,
      path: path ?? this.path,
      mimeType: mimeType ?? this.mimeType,
      sha256: sha256 ?? this.sha256,
    );
  }
}
