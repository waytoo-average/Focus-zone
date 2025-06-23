// lib/database_helper.dart

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// Data Model for our Custom Zikr
class CustomZikr {
  final int? id;
  final String text;
  final int targetCount;
  int currentCount;      // NEW: To cache counter progress
  String? lastCompletedDate; // Renamed for clarity
  int dailyCount;          // Renamed from 'streak' for new logic

  CustomZikr({
    this.id,
    required this.text,
    required this.targetCount,
    required this.currentCount,
    this.lastCompletedDate,
    this.dailyCount = 0,
  });

  // Convert a Zikr object into a Map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'targetCount': targetCount,
      'currentCount': currentCount,
      'lastCompletedDate': lastCompletedDate,
      'dailyCount': dailyCount,
    };
  }

  // Create a Zikr object from a Map.
  factory CustomZikr.fromMap(Map<String, dynamic> map) {
    return CustomZikr(
      id: map['id'],
      text: map['text'],
      targetCount: map['targetCount'],
      currentCount: map['currentCount'],
      lastCompletedDate: map['lastCompletedDate'],
      dailyCount: map['dailyCount'],
    );
  }
}


// Database Helper Singleton Class
class DatabaseHelper {
  static const _databaseName = "MyAzkar.db";
  // Bumping the version will trigger the onUpgrade method for existing users
  static const _databaseVersion = 2;

  static const table = 'custom_azkar';
  static const columnId = 'id';
  static const columnText = 'text';
  static const columnTargetCount = 'targetCount';
  static const columnCurrentCount = 'currentCount'; // NEW
  static const columnLastCompleted = 'lastCompletedDate'; // Renamed
  static const columnDailyCount = 'dailyCount'; // Renamed


  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnText TEXT NOT NULL,
            $columnTargetCount INTEGER NOT NULL,
            $columnCurrentCount INTEGER NOT NULL,
            $columnLastCompleted TEXT,
            $columnDailyCount INTEGER NOT NULL DEFAULT 0
          )
          ''');
  }

  // Handle database schema changes when the version number is increased.
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // We are upgrading from version 1 to 2
      await db.execute('ALTER TABLE $table RENAME COLUMN streak TO $columnDailyCount');
      await db.execute('ALTER TABLE $table RENAME COLUMN lastCompleted TO $columnLastCompleted');
      await db.execute('ALTER TABLE $table ADD COLUMN $columnCurrentCount INTEGER NOT NULL DEFAULT 0');

      // Initialize currentCount to targetCount for existing entries
      await db.rawUpdate('UPDATE $table SET $columnCurrentCount = $columnTargetCount');
    }
  }

  Future<int> insert(CustomZikr zikr) async {
    Database db = await instance.database;
    return await db.insert(table, zikr.toMap());
  }

  Future<List<CustomZikr>> getAzkar() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(table);
    return List.generate(maps.length, (i) {
      return CustomZikr.fromMap(maps[i]);
    });
  }

  Future<int> update(CustomZikr zikr) async {
    Database db = await instance.database;
    return await db.update(table, zikr.toMap(),
        where: '$columnId = ?', whereArgs: [zikr.id]);
  }

  // Specifically update only the current counter value.
  Future<int> updateCurrentCount(int id, int count) async {
    Database db = await instance.database;
    return await db.update(
        table,
        {columnCurrentCount: count},
        where: '$columnId = ?',
        whereArgs: [id]
    );
  }

  Future<int> delete(int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  // NEW LOGIC: Mark as completed for today and update daily count.
  Future<void> completeZikr(int id) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(table, where: '$columnId = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      CustomZikr zikr = CustomZikr.fromMap(maps.first);

      final today = DateTime.now();
      final todayDateString = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      if (zikr.lastCompletedDate == todayDateString) {
        zikr.dailyCount++; // Already completed today, just increment
      } else {
        zikr.dailyCount = 1; // First completion for today
      }

      zikr.lastCompletedDate = todayDateString;
      zikr.currentCount = zikr.targetCount; // Reset counter for next time
      await update(zikr);
    }
  }
}