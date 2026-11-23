import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

abstract interface class JsonCache {
  Future<Map<String, dynamic>?> read(String key);
  Future<void> write(String key, Map<String, dynamic> value);
}

/// Small on-device cache for API responses. SQLite is used on Android, iOS,
/// and macOS; unsupported platforms keep using the API without local caching.
class LocalJsonCache implements JsonCache {
  LocalJsonCache._();

  static final LocalJsonCache instance = LocalJsonCache._();

  Database? _database;
  Future<Database?>? _opening;

  @override
  Future<Map<String, dynamic>?> read(String key) async {
    final database = await _open();
    if (database == null) return null;

    try {
      final rows = await database.query(
        'api_cache',
        columns: const ['json'],
        where: 'cache_key = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      final decoded = jsonDecode(rows.first['json']! as String);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    final database = await _open();
    if (database == null) return;

    try {
      await database.insert(
        'api_cache',
        {
          'cache_key': key,
          'json': jsonEncode(value),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {
      // Cache failures must not turn a successful API request into an error.
    }
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
    if (_database != null) return _database;
    return _opening ??= _openDatabase();
  }

  Future<Database?> _openDatabase() async {
    try {
      final databasePath = await getDatabasesPath();
      _database = await openDatabase(
        path.join(databasePath, 'an_tam_pharma_cache.db'),
        version: 1,
        onCreate: (db, version) => db.execute('''
          CREATE TABLE api_cache (
            cache_key TEXT PRIMARY KEY,
            json TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        '''),
      );
      return _database;
    } catch (_) {
      _opening = null;
      return null;
    }
  }
}
