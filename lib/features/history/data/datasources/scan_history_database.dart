import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:fileguard/features/history/domain/repositories/scan_history_repository.dart';
import 'package:fileguard/features/scanner/domain/models/analysis_stats.dart';
import 'package:fileguard/features/scanner/domain/models/scan_report.dart';
import 'package:fileguard/features/scanner/domain/models/scan_verdict.dart';

/// Implementação de persistência local SQLite para o histórico de análises.
class ScanHistoryDatabase implements ScanHistoryRepository {
  ScanHistoryDatabase({this.database});

  Database? database;

  static const String _tableName = 'scan_reports';
  static const int _dbVersion = 1;

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
            mime_type TEXT
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_scan_date ON $_tableName (scan_date DESC)',
        );
      },
    );
    return database!;
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

      return ScanReport(
        id: row['id'] as String,
        sha256: row['sha256'] as String,
        fileName: row['file_name'] as String,
        fileSize: row['file_size'] as int,
        scanDate: DateTime.fromMillisecondsSinceEpoch(scanDateEpoch),
        stats: stats,
        verdict: verdict,
        permalink: row['permalink'] as String?,
        mimeType: row['mime_type'] as String?,
      );
    }).toList();
  }

  @override
  Future<void> saveReport(ScanReport report) async {
    final db = await _getDatabase();
    await db.insert(
      _tableName,
      {
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
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
