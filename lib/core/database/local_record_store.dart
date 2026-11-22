import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

/// Một bản ghi lưu trên thiết bị, kèm cờ trạng thái đồng bộ.
class LocalRecord {
  const LocalRecord({
    required this.id,
    required this.data,
    required this.synced,
    required this.deleted,
  });

  final String id;
  final Map<String, dynamic> data;
  final bool synced;
  final bool deleted;

  LocalRecord copyWith({bool? synced, bool? deleted}) {
    return LocalRecord(
      id: id,
      data: data,
      synced: synced ?? this.synced,
      deleted: deleted ?? this.deleted,
    );
  }
}

/// Kho dữ liệu SQLite trên thiết bị (offline-first) cho nhắc thuốc, hồ sơ sức
/// khỏe, yêu thích... Mỗi bản ghi thuộc một `owner` (user id) và một `kind`.
///
/// Trên nền tảng không hỗ trợ sqflite (web/desktop) sẽ dùng bộ nhớ tạm để ứng
/// dụng vẫn chạy được.
class LocalRecordStore {
  LocalRecordStore._();

  static final LocalRecordStore instance = LocalRecordStore._();

  static const String _table = 'local_records';

  Database? _database;
  Future<Database?>? _opening;
  final Map<String, LocalRecord> _memory = <String, LocalRecord>{};

  String _key(String owner, String kind, String id) => '$owner|$kind|$id';

  Future<List<LocalRecord>> list(
    String owner,
    String kind, {
    bool includeDeleted = false,
  }) async {
    final database = await _open();
    if (database == null) {
      return _memory.entries
          .where((entry) => entry.key.startsWith('$owner|$kind|'))
          .map((entry) => entry.value)
          .where((record) => includeDeleted || !record.deleted)
          .toList();
    }

    final rows = await database.query(
      _table,
      where: includeDeleted
          ? 'owner = ? AND kind = ?'
          : 'owner = ? AND kind = ? AND deleted = 0',
      whereArgs: [owner, kind],
      orderBy: 'updated_at ASC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<List<LocalRecord>> pending(String owner, String kind) async {
    final all = await list(owner, kind, includeDeleted: true);
    return all.where((record) => !record.synced).toList();
  }

  Future<LocalRecord?> find(String owner, String kind, String id) async {
    final all = await list(owner, kind, includeDeleted: true);
    for (final record in all) {
      if (record.id == id) {
        return record;
      }
    }
    return null;
  }

  Future<void> upsert(
    String owner,
    String kind,
    String id,
    Map<String, dynamic> data, {
    bool synced = false,
  }) async {
    final database = await _open();
    final record = LocalRecord(
      id: id,
      data: data,
      synced: synced,
      deleted: false,
    );
    if (database == null) {
      _memory[_key(owner, kind, id)] = record;
      return;
    }

    await database.insert(_table, {
      'owner': owner,
      'kind': kind,
      'id': id,
      'json': jsonEncode(data),
      'synced': synced ? 1 : 0,
      'deleted': 0,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Xóa mềm: giữ lại để lần đồng bộ sau gửi lệnh xóa lên máy chủ.
  Future<void> markDeleted(String owner, String kind, String id) async {
    final database = await _open();
    if (database == null) {
      final key = _key(owner, kind, id);
      final current = _memory[key];
      if (current != null) {
        _memory[key] = current.copyWith(synced: false, deleted: true);
      }
      return;
    }

    await database.update(
      _table,
      {'deleted': 1, 'synced': 0},
      where: 'owner = ? AND kind = ? AND id = ?',
      whereArgs: [owner, kind, id],
    );
  }

  Future<void> markSynced(String owner, String kind, String id) async {
    final database = await _open();
    if (database == null) {
      final key = _key(owner, kind, id);
      final current = _memory[key];
      if (current != null) {
        _memory[key] = current.copyWith(synced: true);
      }
      return;
    }

    await database.update(
      _table,
      {'synced': 1},
      where: 'owner = ? AND kind = ? AND id = ?',
      whereArgs: [owner, kind, id],
    );
  }

  Future<void> purge(String owner, String kind, String id) async {
    final database = await _open();
    if (database == null) {
      _memory.remove(_key(owner, kind, id));
      return;
    }

    await database.delete(
      _table,
      where: 'owner = ? AND kind = ? AND id = ?',
      whereArgs: [owner, kind, id],
    );
  }

  LocalRecord _fromRow(Map<String, Object?> row) {
    Map<String, dynamic> data = <String, dynamic>{};
    try {
      final decoded = jsonDecode(row['json']! as String);
      if (decoded is Map) {
        data = decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {
      data = <String, dynamic>{};
    }
    return LocalRecord(
      id: row['id']! as String,
      data: data,
      synced: (row['synced'] as int?) == 1,
      deleted: (row['deleted'] as int?) == 1,
    );
  }

  Future<Database?> _open() async {
    if (kIsWeb ||
        !const {
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
        }.contains(defaultTargetPlatform)) {
      return null;
    }

    final existing = _database;
    if (existing != null) {
      return existing;
    }

    return _opening ??= _openDatabase();
  }

  Future<Database?> _openDatabase() async {
    try {
      final databasePath = await getDatabasesPath();
      final database = await openDatabase(
        path.join(databasePath, 'an_tam_pharma_local_records.db'),
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $_table (
              owner TEXT NOT NULL,
              kind TEXT NOT NULL,
              id TEXT NOT NULL,
              json TEXT NOT NULL,
              synced INTEGER NOT NULL DEFAULT 0,
              deleted INTEGER NOT NULL DEFAULT 0,
              updated_at TEXT NOT NULL,
              PRIMARY KEY (owner, kind, id)
            )
          ''');
        },
      );
      _database = database;
      return database;
    } catch (_) {
      return null;
    }
  }
}
