import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../shared/models/app_enums.dart';
import '../../shared/models/inspection.dart';
import '../../shared/models/property.dart';

abstract interface class TulkhuurRepository {
  Future<List<Property>> loadProperties();
  Future<List<Inspection>> loadInspections();
  Future<void> saveProperty(Property property);
  Future<void> saveInspection(Inspection inspection);
  Future<void> deleteProperty(String propertyId);
}

class LocalDatabase implements TulkhuurRepository {
  Database? _database;

  Future<Database> get database async => _database ??= await _open();

  Future<Database> _open() async {
    final root = await getDatabasesPath();
    return openDatabase(
      p.join(root, 'rentcheck.db'),
      version: 2,
      onConfigure: (database) => database.execute('PRAGMA foreign_keys = ON'),
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await database.execute(
            'ALTER TABLE properties ADD COLUMN dirty INTEGER NOT NULL DEFAULT 1',
          );
          await database.execute(
            'ALTER TABLE inspections ADD COLUMN dirty INTEGER NOT NULL DEFAULT 1',
          );
          await _createSyncTables(database);
        }
      },
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE properties (
            id TEXT PRIMARY KEY,
            payload TEXT NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await database.execute('''
          CREATE TABLE inspections (
            id TEXT PRIMARY KEY,
            property_id TEXT NOT NULL,
            status TEXT NOT NULL,
            payload TEXT NOT NULL,
            updated_at INTEGER NOT NULL,
            FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE RESTRICT
          )
        ''');
        await database.execute(
          'CREATE INDEX inspections_property_id_idx ON inspections(property_id)',
        );
        await database.execute(
          'CREATE INDEX inspections_status_updated_idx '
          'ON inspections(status, updated_at DESC)',
        );
        await _createSyncTables(database);
      },
    );
  }

  /// Сервертэй тааруулахад хэрэглэгдэх туслах хүснэгтүүд.
  static Future<void> _createSyncTables(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS sync_state (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS deleted_records (
        id TEXT PRIMARY KEY,
        kind TEXT NOT NULL,
        deleted_at INTEGER NOT NULL
      )
    ''');
  }

  @override
  Future<List<Property>> loadProperties() async {
    final rows = await (await database).query(
      'properties',
      orderBy: 'updated_at DESC',
    );
    return rows
        .map(
          (row) => Property.fromJson(
            Map<String, Object?>.from(
              jsonDecode(row['payload']! as String) as Map,
            ),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<Inspection>> loadInspections() async {
    final rows = await (await database).query(
      'inspections',
      orderBy: 'updated_at DESC',
    );
    return rows
        .map(
          (row) => Inspection.fromJson(
            Map<String, Object?>.from(
              jsonDecode(row['payload']! as String) as Map,
            ),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> saveProperty(Property property) async {
    await (await database).insert('properties', {
      'id': property.id,
      'payload': jsonEncode(property.toJson()),
      'updated_at': property.updatedAt.millisecondsSinceEpoch,
      'dirty': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> saveInspection(Inspection inspection) async {
    await (await database).insert('inspections', {
      'id': inspection.id,
      'property_id': inspection.propertyId,
      'status': inspection.status.databaseValue,
      'payload': jsonEncode(inspection.toJson()),
      'updated_at': inspection.updatedAt.millisecondsSinceEpoch,
      'dirty': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> deleteProperty(String propertyId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('properties', where: 'id = ?', whereArgs: [propertyId]);
      await txn.insert('deleted_records', {
        'id': propertyId,
        'kind': 'property',
        'deleted_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  // ------------------------------------------------------------- sync API ---

  /// Сервер рүү илгээгээгүй байрнууд.
  Future<List<Property>> dirtyProperties() async => _decodeProperties(
    await (await database).query('properties', where: 'dirty = 1'),
  );

  /// Сервер рүү илгээгээгүй үзлэгүүд.
  Future<List<Inspection>> dirtyInspections() async => _decodeInspections(
    await (await database).query('inspections', where: 'dirty = 1'),
  );

  /// Серверт хүрсэн гэж тэмдэглэнэ.
  Future<void> markClean(String table, String id) async =>
      (await database).update(
        table,
        {'dirty': 0},
        where: 'id = ?',
        whereArgs: [id],
      );

  /// Серверээс татсан өгөгдлийг хадгална (dirty болгохгүй).
  Future<void> savePropertyFromRemote(Property property) async {
    final db = await database;
    final existing = await db.query(
      'properties',
      columns: ['dirty', 'updated_at'],
      where: 'id = ?',
      whereArgs: [property.id],
    );
    // Локал дээр илгээгээгүй, илүү шинэ өөрчлөлт байвал хөндөхгүй.
    if (existing.isNotEmpty &&
        existing.first['dirty'] == 1 &&
        (existing.first['updated_at']! as int) >=
            property.updatedAt.millisecondsSinceEpoch) {
      return;
    }
    await db.insert('properties', {
      'id': property.id,
      'payload': jsonEncode(property.toJson()),
      'updated_at': property.updatedAt.millisecondsSinceEpoch,
      'dirty': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveInspectionFromRemote(Inspection inspection) async {
    final db = await database;
    final existing = await db.query(
      'inspections',
      columns: ['dirty', 'updated_at'],
      where: 'id = ?',
      whereArgs: [inspection.id],
    );
    if (existing.isNotEmpty &&
        existing.first['dirty'] == 1 &&
        (existing.first['updated_at']! as int) >=
            inspection.updatedAt.millisecondsSinceEpoch) {
      return;
    }
    await db.insert('inspections', {
      'id': inspection.id,
      'property_id': inspection.propertyId,
      'status': inspection.status.databaseValue,
      'payload': jsonEncode(inspection.toJson()),
      'updated_at': inspection.updatedAt.millisecondsSinceEpoch,
      'dirty': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Серверээс устгах хүлээгдэж буй бичлэгүүд.
  Future<List<String>> pendingDeletions() async {
    final rows = await (await database).query(
      'deleted_records',
      where: 'kind = ?',
      whereArgs: ['property'],
    );
    return rows.map((row) => row['id']! as String).toList(growable: false);
  }

  Future<void> clearDeletion(String id) async => (await database).delete(
    'deleted_records',
    where: 'id = ?',
    whereArgs: [id],
  );

  Future<DateTime?> lastPulledAt() async {
    final rows = await (await database).query(
      'sync_state',
      where: 'key = ?',
      whereArgs: ['last_pulled_at'],
    );
    if (rows.isEmpty) return null;
    return DateTime.tryParse(rows.first['value']! as String);
  }

  Future<void> setLastPulledAt(DateTime value) async =>
      (await database).insert('sync_state', {
        'key': 'last_pulled_at',
        'value': value.toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

  /// Илгээгээгүй өөрчлөлтийн тоо (UI-д харуулахад).
  Future<int> pendingChangeCount() async {
    final db = await database;
    final counts = await Future.wait([
      db.rawQuery('SELECT COUNT(*) c FROM properties WHERE dirty = 1'),
      db.rawQuery('SELECT COUNT(*) c FROM inspections WHERE dirty = 1'),
      db.rawQuery('SELECT COUNT(*) c FROM deleted_records'),
    ]);
    var total = 0;
    for (final rows in counts) {
      total += rows.first['c']! as int;
    }
    return total;
  }

  List<Property> _decodeProperties(List<Map<String, Object?>> rows) => rows
      .map(
        (row) => Property.fromJson(
          Map<String, Object?>.from(
            jsonDecode(row['payload']! as String) as Map,
          ),
        ),
      )
      .toList(growable: false);

  List<Inspection> _decodeInspections(List<Map<String, Object?>> rows) => rows
      .map(
        (row) => Inspection.fromJson(
          Map<String, Object?>.from(
            jsonDecode(row['payload']! as String) as Map,
          ),
        ),
      )
      .toList(growable: false);
}

final tulkhuurRepositoryProvider = Provider<TulkhuurRepository>(
  (ref) => LocalDatabase(),
);
