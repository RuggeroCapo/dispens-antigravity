import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final databaseProvider = FutureProvider<Database>((ref) async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'dispens.db');

  return await openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE food_items (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          expiryDate TEXT NOT NULL,
          expiryType TEXT NOT NULL,
          tags TEXT NOT NULL,
          reminders TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
    },
  );
});
