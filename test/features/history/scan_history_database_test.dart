import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'package:fileguard/features/history/data/datasources/scan_history_database.dart';
import 'package:fileguard/features/scanner/domain/models/analysis_stats.dart';
import 'package:fileguard/features/scanner/domain/models/engine_result.dart';
import 'package:fileguard/features/scanner/domain/models/scan_report.dart';
import 'package:fileguard/features/scanner/domain/models/scan_verdict.dart';
import 'package:fileguard/features/scanner/domain/models/total_votes.dart';

/// Implementação de teste para [Database] que simula armazenamento e execução SQL em memória.
class FakeDatabase implements Database {
  final List<String> executedSql = [];
  final List<Map<String, dynamic>> rows = [];

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    executedSql.add(sql);
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    return List<Map<String, Object?>>.from(rows);
  }

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    rows.removeWhere((r) => r['id'] == values['id']);
    rows.add(Map<String, dynamic>.from(values));
    return 1;
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    if (where == null) {
      final count = rows.length;
      rows.clear();
      return count;
    }
    if (where == 'id = ?' && whereArgs != null && whereArgs.isNotEmpty) {
      final idToDelete = whereArgs.first;
      final before = rows.length;
      rows.removeWhere((r) => r['id'] == idToDelete);
      return before - rows.length;
    }
    return 0;
  }

  @override
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action, {bool? exclusive}) async {
    return action(FakeTransaction(this));
  }

  @override
  Batch batch() => FakeBatch(this);

  // Métodos de contrato não utilizados pelo ScanHistoryDatabase
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTransaction implements Transaction {
  FakeTransaction(this.fakeDb);
  final FakeDatabase fakeDb;

  @override
  Batch batch() => FakeBatch(fakeDb);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeBatch implements Batch {
  FakeBatch(this.fakeDb);
  final FakeDatabase fakeDb;
  final List<Map<String, Object?>> pendingInserts = [];

  @override
  void insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) {
    pendingInserts.add(values);
  }

  @override
  Future<List<Object?>> commit({
    bool? exclusive,
    bool? noResult,
    bool? continueOnError,
  }) async {
    for (final values in pendingInserts) {
      await fakeDb.insert('scan_history', values);
    }
    return List.filled(pendingInserts.length, 1);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ScanHistoryDatabase v2 & Migration Tests', () {
    late FakeDatabase fakeDb;
    late ScanHistoryDatabase historyDb;

    setUp(() {
      fakeDb = FakeDatabase();
      historyDb = ScanHistoryDatabase(database: fakeDb);
    });

    test('1. migrateToV2 adiciona todas as 7 novas colunas sem apagar a tabela', () async {
      await ScanHistoryDatabase.migrateToV2(fakeDb);

      expect(fakeDb.executedSql.length, equals(7));
      expect(fakeDb.executedSql[0], contains('ADD COLUMN results_json TEXT'));
      expect(fakeDb.executedSql[1], contains('ADD COLUMN md5 TEXT'));
      expect(fakeDb.executedSql[2], contains('ADD COLUMN sha1 TEXT'));
      expect(fakeDb.executedSql[3], contains('ADD COLUMN tags TEXT'));
      expect(fakeDb.executedSql[4], contains('ADD COLUMN reputation INTEGER'));
      expect(fakeDb.executedSql[5], contains('ADD COLUMN total_votes_json TEXT'));
      expect(fakeDb.executedSql[6], contains('ADD COLUMN file_extension TEXT'));
    });

    test('2. Salva e recupera relatório completo com resultados de motores, hashes e metadados', () async {
      final report = ScanReport(
        id: 'report_full_1',
        sha256: '275a021bbfb6489e54d471899f7db9d1663fc695ec2fe2a2c4538aabf651fd0f',
        md5: '44d88612fea8a8f36de82e1278abb02f',
        sha1: '3395856ce81f2b7382dee72602f798b642f14140',
        fileName: 'sample_payload.bin',
        fileSize: 524288,
        scanDate: DateTime(2026, 11, 10, 14, 30),
        stats: const AnalysisStats(
          malicious: 3,
          suspicious: 1,
          undetected: 60,
          harmless: 6,
        ),
        verdict: ScanVerdict.malicious,
        permalink: 'https://www.virustotal.com/gui/file/275a021bbfb6',
        mimeType: 'application/octet-stream',
        fileExtension: 'bin',
        reputation: -10,
        tags: const ['binary', 'packed', 'trojan'],
        totalVotes: const TotalVotes(harmless: 2, malicious: 15),
        results: {
          'Avast': const EngineResult(
            engineName: 'Avast',
            category: 'malicious',
            result: 'Win32:Evo-gen',
            method: 'blacklist',
            engineVersion: '23.1',
            engineUpdate: '20261110',
          ),
          'Kaspersky': const EngineResult(
            engineName: 'Kaspersky',
            category: 'suspicious',
            result: 'HEUR:Trojan.Generic',
            method: 'heuristic',
            engineVersion: '22.0',
            engineUpdate: '20261110',
          ),
        },
      );

      await historyDb.saveReport(report);

      expect(fakeDb.rows.length, equals(1));
      final insertedRow = fakeDb.rows.first;
      expect(insertedRow['id'], equals('report_full_1'));
      expect(insertedRow['md5'], equals('44d88612fea8a8f36de82e1278abb02f'));
      expect(insertedRow['sha1'], equals('3395856ce81f2b7382dee72602f798b642f14140'));
      expect(insertedRow['reputation'], equals(-10));
      expect(insertedRow['file_extension'], equals('bin'));
      expect(insertedRow['tags'], equals(jsonEncode(['binary', 'packed', 'trojan'])));
      expect(insertedRow['total_votes_json'], contains('"malicious":15'));
      expect(insertedRow['results_json'], contains('"engine_name":"Avast"'));

      // Recuperação
      final recoveredReports = await historyDb.getReports();
      expect(recoveredReports.length, equals(1));

      final recovered = recoveredReports.first;
      expect(recovered.id, equals(report.id));
      expect(recovered.sha256, equals(report.sha256));
      expect(recovered.md5, equals(report.md5));
      expect(recovered.sha1, equals(report.sha1));
      expect(recovered.fileName, equals(report.fileName));
      expect(recovered.fileSize, equals(report.fileSize));
      expect(recovered.scanDate.millisecondsSinceEpoch, equals(report.scanDate.millisecondsSinceEpoch));
      expect(recovered.verdict, equals(report.verdict));
      expect(recovered.stats.malicious, equals(3));
      expect(recovered.stats.undetected, equals(60));
      expect(recovered.reputation, equals(-10));
      expect(recovered.fileExtension, equals('bin'));
      expect(recovered.tags, equals(['binary', 'packed', 'trojan']));
      expect(recovered.totalVotes, equals(const TotalVotes(harmless: 2, malicious: 15)));

      // Validação dos motores reconstruídos
      expect(recovered.results.length, equals(2));
      expect(recovered.results['Avast']!.result, equals('Win32:Evo-gen'));
      expect(recovered.results['Avast']!.isMalicious, isTrue);
      expect(recovered.results['Kaspersky']!.isSuspicious, isTrue);
    });

    test('3. Recupera registros legados da v1 (com colunas nulas) de forma transparente', () async {
      // Simula uma linha preexistente da versão 1 onde os novos campos são NULL
      fakeDb.rows.add({
        'id': 'legacy_record_1',
        'sha256': '11223344556677889900aabbccddeeff11223344556677889900aabbccddeeff',
        'file_name': 'legacy_invoice.pdf',
        'file_size': 12345,
        'scan_date': 1672531199000,
        'verdict': 'noDetections',
        'malicious': 0,
        'suspicious': 0,
        'undetected': 65,
        'harmless': 5,
        'timeout': 0,
        'failure': 0,
        'type_unsupported': 0,
        'permalink': 'https://www.virustotal.com/gui/file/112233',
        'mime_type': 'application/pdf',
        'results_json': null,
        'md5': null,
        'sha1': null,
        'tags': null,
        'reputation': null,
        'total_votes_json': null,
        'file_extension': null,
      });

      final reports = await historyDb.getReports();
      expect(reports.length, equals(1));

      final report = reports.first;
      expect(report.id, equals('legacy_record_1'));
      expect(report.fileName, equals('legacy_invoice.pdf'));
      expect(report.verdict, equals(ScanVerdict.noDetections));
      expect(report.stats.undetected, equals(65));
      expect(report.stats.totalEngines, equals(70));

      // Novos campos com valores ausentes
      expect(report.results, isEmpty);
      expect(report.threatEngines, isEmpty);
      expect(report.cleanEngines, isEmpty);
      expect(report.md5, isNull);
      expect(report.sha1, isNull);
      expect(report.tags, isEmpty);
      expect(report.reputation, isNull);
      expect(report.totalVotes, isNull);
      expect(report.fileExtension, isNull);
    });

    test('4. Tolera JSONs malformados nas colunas TEXT da v2 sem lançar exceção', () async {
      fakeDb.rows.add({
        'id': 'corrupted_json_record',
        'sha256': 'sha256_corrupt',
        'file_name': 'corrupt.dat',
        'file_size': 500,
        'scan_date': 1672531199000,
        'verdict': 'inconclusive',
        'malicious': 0,
        'suspicious': 0,
        'undetected': 0,
        'harmless': 0,
        'timeout': 0,
        'failure': 0,
        'type_unsupported': 0,
        'permalink': null,
        'mime_type': null,
        'results_json': '{invalid_json',
        'md5': 'valid_md5',
        'sha1': null,
        'tags': '[invalid_tag_json',
        'reputation': null,
        'total_votes_json': '{invalid_votes',
        'file_extension': null,
      });

      final reports = await historyDb.getReports();
      expect(reports.length, equals(1));

      final report = reports.first;
      expect(report.id, equals('corrupted_json_record'));
      expect(report.md5, equals('valid_md5'));
      expect(report.results, isEmpty);
      expect(report.tags, isEmpty);
      expect(report.totalVotes, isNull);
    });

    test('5. Exclui relatório por id e limpa histórico completo', () async {
      fakeDb.rows.addAll([
        {'id': 'r1', 'sha256': 'h1', 'file_name': 'f1', 'file_size': 1, 'scan_date': 100, 'verdict': 'noDetections', 'malicious': 0, 'suspicious': 0, 'undetected': 1, 'harmless': 0, 'timeout': 0, 'failure': 0, 'type_unsupported': 0},
        {'id': 'r2', 'sha256': 'h2', 'file_name': 'f2', 'file_size': 2, 'scan_date': 200, 'verdict': 'malicious', 'malicious': 1, 'suspicious': 0, 'undetected': 0, 'harmless': 0, 'timeout': 0, 'failure': 0, 'type_unsupported': 0},
      ]);

      await historyDb.deleteReport('r1');
      expect(fakeDb.rows.length, equals(1));
      expect(fakeDb.rows.first['id'], equals('r2'));

      await historyDb.clearHistory();
      expect(fakeDb.rows, isEmpty);
    });

    test('6. saveReports salva múltiplos relatórios em lote transacional com replace de duplicatas', () async {
      final report1 = ScanReport(
        id: 'rep_1',
        sha256: 'sha256_1',
        fileName: 'file1.txt',
        fileSize: 100,
        scanDate: DateTime.now(),
        stats: const AnalysisStats(undetected: 10),
        verdict: ScanVerdict.noDetections,
      );
      final report2 = ScanReport(
        id: 'rep_2',
        sha256: 'sha256_2',
        fileName: 'file2.txt',
        fileSize: 200,
        scanDate: DateTime.now(),
        stats: const AnalysisStats(malicious: 1),
        verdict: ScanVerdict.malicious,
      );

      final count = await historyDb.saveReports([report1, report2]);
      expect(count, equals(2));
      expect(fakeDb.rows.length, equals(2));

      // Re-inserção do rep_1 com novo nome substitui o registro existente
      final report1Updated = ScanReport(
        id: 'rep_1',
        sha256: 'sha256_1',
        fileName: 'file1_updated.txt',
        fileSize: 150,
        scanDate: DateTime.now(),
        stats: const AnalysisStats(undetected: 10),
        verdict: ScanVerdict.noDetections,
      );

      final countUpdated = await historyDb.saveReports([report1Updated]);
      expect(countUpdated, equals(1));
      expect(fakeDb.rows.length, equals(2));
      expect(fakeDb.rows.firstWhere((r) => r['id'] == 'rep_1')['file_name'], equals('file1_updated.txt'));
    });
  });
}
