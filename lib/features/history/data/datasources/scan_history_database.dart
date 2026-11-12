import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:fileguard/features/history/domain/repositories/scan_history_repository.dart';
import 'package:fileguard/features/scanner/domain/models/analysis_stats.dart';
import 'package:fileguard/features/scanner/domain/models/engine_result.dart';
import 'package:fileguard/features/scanner/domain/models/scan_report.dart';
import 'package:fileguard/features/scanner/domain/models/scan_verdict.dart';
import 'package:fileguard/features/scanner/domain/models/total_votes.dart';

/// Implementação de persistência local SQLite para o histórico de análises.
class ScanHistoryDatabase implements ScanHistoryRepository {
  ScanHistoryDatabase({this.database});

  Database? database;

  static const String _tableName = 'scan_reports';
  static const int _dbVersion = 2;

  Future<Database> _getDatabase() async {
    if (database != null) return database!;

    final databasesPath = await getDatabasesPath();
    final dbPath = p.join(databasesPath, 'fileguard_history.db');

    database = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            sha256 TEXT NOT NULL,
            file_name TEXT NOT NULL,
            file_size INTEGER NOT NULL,
            scan_date INTEGER NOT NULL,
            verdict TEXT NOT NULL,
            malicious INTEGER NOT NULL,
            suspicious INTEGER NOT NULL,
            undetected INTEGER NOT NULL,
            harmless INTEGER NOT NULL,
            timeout INTEGER NOT NULL,
            failure INTEGER NOT NULL,
            type_unsupported INTEGER NOT NULL,
            permalink TEXT,
            mime_type TEXT,
            results_json TEXT,
            md5 TEXT,
            sha1 TEXT,
            tags TEXT,
            reputation INTEGER,
            total_votes_json TEXT,
            file_extension TEXT
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_scan_date ON $_tableName (scan_date DESC)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await migrateToV2(db);
        }
      },
    );
    return database!;
  }

  /// Migração incremental da versão 1 para a versão 2.
  /// Adiciona as novas colunas preservando integralmente os registros existentes.
  static Future<void> migrateToV2(DatabaseExecutor db) async {
    await db.execute('ALTER TABLE $_tableName ADD COLUMN results_json TEXT;');
    await db.execute('ALTER TABLE $_tableName ADD COLUMN md5 TEXT;');
    await db.execute('ALTER TABLE $_tableName ADD COLUMN sha1 TEXT;');
    await db.execute('ALTER TABLE $_tableName ADD COLUMN tags TEXT;');
    await db.execute('ALTER TABLE $_tableName ADD COLUMN reputation INTEGER;');
    await db.execute('ALTER TABLE $_tableName ADD COLUMN total_votes_json TEXT;');
    await db.execute('ALTER TABLE $_tableName ADD COLUMN file_extension TEXT;');
  }

  @override
  Future<List<ScanReport>> getReports() async {
    final db = await _getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'scan_date DESC',
    );

    return maps.map((row) {
      final stats = AnalysisStats(
        malicious: row['malicious'] as int? ?? 0,
        suspicious: row['suspicious'] as int? ?? 0,
        undetected: row['undetected'] as int? ?? 0,
        harmless: row['harmless'] as int? ?? 0,
        timeout: row['timeout'] as int? ?? 0,
        failure: row['failure'] as int? ?? 0,
        typeUnsupported: row['type_unsupported'] as int? ?? 0,
      );

      final verdictStr = row['verdict'] as String? ?? 'inconclusive';
      final verdict = ScanVerdict.values.firstWhere(
        (v) => v.name == verdictStr,
        orElse: () => ScanVerdict.inconclusive,
      );

      final scanDateEpoch = row['scan_date'] as int? ?? 0;

      // Desserializa resultados individuais de motores (v2)
      final Map<String, EngineResult> results = {};
      final rawResults = row['results_json'] as String?;
      if (rawResults != null && rawResults.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(rawResults);
          if (decoded is Map<String, dynamic>) {
            decoded.forEach((key, val) {
              if (val is Map<String, dynamic>) {
                results[key] = EngineResult.fromJson(key, val);
              }
            });
          }
        } catch (_) {}
      }

      // Desserializa tags (v2)
      List<String> tags = const [];
      final rawTags = row['tags'] as String?;
      if (rawTags != null && rawTags.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(rawTags);
          if (decoded is List) {
            tags = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {}
      }

      // Desserializa votos da comunidade (v2)
      TotalVotes? totalVotes;
      final rawVotes = row['total_votes_json'] as String?;
      if (rawVotes != null && rawVotes.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(rawVotes);
          if (decoded is Map<String, dynamic>) {
            totalVotes = TotalVotes.fromJson(decoded);
          }
        } catch (_) {}
      }

      return ScanReport(
        id: row['id'] as String? ?? '',
        sha256: row['sha256'] as String? ?? '',
        fileName: row['file_name'] as String? ?? 'Arquivo',
        fileSize: row['file_size'] as int? ?? 0,
        scanDate: DateTime.fromMillisecondsSinceEpoch(scanDateEpoch),
        stats: stats,
        verdict: verdict,
        results: results,
        permalink: row['permalink'] as String?,
        mimeType: row['mime_type'] as String?,
        md5: row['md5'] as String?,
        sha1: row['sha1'] as String?,
        tags: tags,
        reputation: row['reputation'] as int?,
        totalVotes: totalVotes,
        fileExtension: row['file_extension'] as String?,
      );
    }).toList();
  }

  Map<String, dynamic> _reportToMap(ScanReport report) {
    return {
      'id': report.id,
      'sha256': report.sha256,
      'file_name': report.fileName,
      'file_size': report.fileSize,
      'scan_date': report.scanDate.millisecondsSinceEpoch,
      'verdict': report.verdict.name,
      'malicious': report.stats.malicious,
      'suspicious': report.stats.suspicious,
      'undetected': report.stats.undetected,
      'harmless': report.stats.harmless,
      'timeout': report.stats.timeout,
      'failure': report.stats.failure,
      'type_unsupported': report.stats.typeUnsupported,
      'permalink': report.permalink,
      'mime_type': report.mimeType,
      'results_json': report.results.isNotEmpty
          ? jsonEncode(report.results.map((k, v) => MapEntry(k, v.toJson())))
          : null,
      'md5': report.md5,
      'sha1': report.sha1,
      'tags': report.tags.isNotEmpty ? jsonEncode(report.tags) : null,
      'reputation': report.reputation,
      'total_votes_json': report.totalVotes != null
          ? jsonEncode(report.totalVotes!.toJson())
          : null,
      'file_extension': report.fileExtension,
    };
  }

  @override
  Future<void> saveReport(ScanReport report) async {
    final db = await _getDatabase();
    await db.insert(
      _tableName,
      _reportToMap(report),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> saveReports(List<ScanReport> reports) async {
    if (reports.isEmpty) return 0;
    final db = await _getDatabase();
    int count = 0;

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final report in reports) {
        batch.insert(
          _tableName,
          _reportToMap(report),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      final results = await batch.commit(noResult: false);
      count = results.length;
    });

    return count;
  }

  @override
  Future<void> deleteReport(String id) async {
    final db = await _getDatabase();
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> clearHistory() async {
    final db = await _getDatabase();
    await db.delete(_tableName);
  }
}
