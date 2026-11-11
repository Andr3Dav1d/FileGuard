import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:fileguard/features/scanner/data/services/sha256_calculator.dart';

void main() {
  group('Sha256Calculator Tests', () {
    const calculator = Sha256Calculator();

    test('Calcula hash SHA-256 correto a partir de bytes em memória', () {
      final bytes = utf8.encode('FileGuard');
      final hash = calculator.calculateFromBytes(bytes);
      expect(
        hash,
        equals('c5784dde94875df13c4535ac133c0049ea014ee16948f31250305522709bd323'),
      );
    });

    test('Calcula hash SHA-256 via streaming em múltiplos chunks', () async {
      final controller = StreamController<List<int>>();
      final streamFuture = calculator.calculateFromStream(controller.stream);

      // Envia em 3 pedaços: "File", "Gu", "ard"
      controller.add(utf8.encode('File'));
      controller.add(utf8.encode('Gu'));
      controller.add(utf8.encode('ard'));
      await controller.close();

      final result = await streamFuture;
      expect(
        result,
        equals('c5784dde94875df13c4535ac133c0049ea014ee16948f31250305522709bd323'),
      );
    });

    test('Calcula hash SHA-256 para entrada vazia (digest padrão do SHA-256)', () {
      final emptyHash = calculator.calculateFromBytes(<int>[]);
      expect(
        emptyHash,
        equals('e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'),
      );
    });
  });
}
