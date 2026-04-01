import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../models/food_item.dart';
import '../services/database_service.dart';

final asyncFoodRepositoryProvider = FutureProvider<FoodRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return FoodRepository(db);
});

class FoodRepository {
  final Database _db;

  FoodRepository(this._db);

  Future<List<FoodItem>> getItems() async {
    final List<Map<String, dynamic>> maps = await _db.query('food_items', orderBy: 'expiryDate ASC');
    return maps.map((e) => FoodItem.fromMap(e)).toList();
  }

  Future<void> addItem(FoodItem item) async {
    await _db.insert('food_items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateItem(FoodItem item) async {
    await _db.update('food_items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> deleteItem(String id) async {
    await _db.delete('food_items', where: 'id = ?', whereArgs: [id]);
  }
}
