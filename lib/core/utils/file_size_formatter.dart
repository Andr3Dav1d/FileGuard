/// Utilitário para formatação de tamanhos de arquivos em unidades legíveis.
abstract final class FileSizeFormatter {
  /// Formata uma quantidade de [bytes] em uma string legível (B, KB, MB, GB).
  ///
  /// - Se [bytes] for nulo ou menor/igual a zero, retorna [fallback] ('Tamanho desconhecido' por padrão).
  /// - Menor que 1024 B: '$bytes B'.
  /// - Menor que 1024 * 1024: '${kb.toStringAsFixed(1)} KB' ou '${kb.round()} KB' se >= 100.
  /// - Menor que 1024 * 1024 * 1024: '${mb.toStringAsFixed(1)} MB'.
  /// - Acima disso: '${gb.toStringAsFixed(1)} GB'.
  static String format(int? bytes, {String fallback = 'Tamanho desconhecido'}) {
    if (bytes == null || bytes <= 0) {
      return fallback;
    }

    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      final kb = bytes / 1024;
      return kb >= 100 ? '${kb.round()} KB' : '${kb.toStringAsFixed(1)} KB';
    }

    if (bytes < 1024 * 1024 * 1024) {
      final mb = bytes / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB';
    }

    final gb = bytes / (1024 * 1024 * 1024);
    return '${gb.toStringAsFixed(1)} GB';
  }
}
