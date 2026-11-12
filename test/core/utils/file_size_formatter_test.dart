import 'package:flutter_test/flutter_test.dart';
import 'package:fileguard/core/utils/file_size_formatter.dart';

void main() {
  group('FileSizeFormatter Tests', () {
    test('Retorna fallback quando bytes é nulo, zero ou negativo', () {
      expect(FileSizeFormatter.format(null), equals('Tamanho desconhecido'));
      expect(FileSizeFormatter.format(0), equals('Tamanho desconhecido'));
      expect(FileSizeFormatter.format(-50), equals('Tamanho desconhecido'));

      // Com fallback customizado
      expect(FileSizeFormatter.format(null, fallback: '-'), equals('-'));
      expect(FileSizeFormatter.format(0, fallback: '-'), equals('-'));
      expect(FileSizeFormatter.format(-10, fallback: 'N/A'), equals('N/A'));
    });

    test('Formata tamanhos em Bytes (< 1024 B)', () {
      expect(FileSizeFormatter.format(1), equals('1 B'));
      expect(FileSizeFormatter.format(512), equals('512 B'));
      expect(FileSizeFormatter.format(1023), equals('1023 B'));
    });

    test('Formata tamanhos em Kilobytes (< 1024 * 1024 B)', () {
      // kb < 100 exibe 1 casa decimal
      expect(FileSizeFormatter.format(1024), equals('1.0 KB'));
      expect(FileSizeFormatter.format(1536), equals('1.5 KB'));
      expect(FileSizeFormatter.format(50 * 1024), equals('50.0 KB'));
      expect(FileSizeFormatter.format((99.4 * 1024).round()), equals('99.4 KB'));

      // kb >= 100 exibe valor arredondado sem decimal
      expect(FileSizeFormatter.format(100 * 1024), equals('100 KB'));
      expect(FileSizeFormatter.format(251904), equals('246 KB'));
      expect(FileSizeFormatter.format(500 * 1024), equals('500 KB'));
    });

    test('Formata tamanhos em Megabytes (< 1024 * 1024 * 1024 B)', () {
      expect(FileSizeFormatter.format(1024 * 1024), equals('1.0 MB'));
      expect(FileSizeFormatter.format((2.4 * 1024 * 1024).round()), equals('2.4 MB'));
      expect(FileSizeFormatter.format(100 * 1024 * 1024), equals('100.0 MB'));
    });

    test('Formata tamanhos em Gigabytes (>= 1024 * 1024 * 1024 B)', () {
      expect(FileSizeFormatter.format(1024 * 1024 * 1024), equals('1.0 GB'));
      expect(FileSizeFormatter.format((2.5 * 1024 * 1024 * 1024).round()), equals('2.5 GB'));
    });
  });
}
