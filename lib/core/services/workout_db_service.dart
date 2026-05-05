import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:kinecue/core/models/workout_session.dart';
import 'package:kinecue/core/utils/logger.dart';

/// SQLite 持久化服务，存取训练记录。
class WorkoutDbService {
  WorkoutDbService._();
  static final WorkoutDbService instance = WorkoutDbService._();

  static const _dbName = 'kinecue.db';
  static const _dbVersion = 1;
  static const _table = 'workout_sessions';

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  /// 初始化数据库（app 启动时调用）。
  Future<void> init() async {
    _db = await _open();
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            exercise_type TEXT NOT NULL,
            started_at TEXT NOT NULL,
            total_sets INTEGER NOT NULL,
            total_reps INTEGER NOT NULL,
            total_duration_seconds INTEGER NOT NULL,
            error_counts TEXT NOT NULL,
            set_summaries TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE INDEX idx_${_table}_started_at
          ON $_table (started_at DESC)
        ''');
      },
    );
  }

  /// 插入训练记录，返回自增 id。
  Future<int> insertSession(WorkoutSession session) async {
    final db = await _database;
    final id = await db.insert(_table, session.toMap());
    Log.d('Saved workout session #$id', tag: 'DB');
    return id;
  }

  /// 获取最近的训练记录。
  Future<List<WorkoutSession>> getRecentSessions({int limit = 10}) async {
    final db = await _database;
    final rows = await db.query(
      _table,
      orderBy: 'started_at DESC',
      limit: limit,
    );
    return rows.map(WorkoutSession.fromMap).toList();
  }

  /// 根据 id 获取单条记录。
  Future<WorkoutSession?> getSession(int id) async {
    final db = await _database;
    final rows = await db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return WorkoutSession.fromMap(rows.first);
  }

  /// 删除单条记录。
  Future<void> deleteSession(int id) async {
    final db = await _database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
