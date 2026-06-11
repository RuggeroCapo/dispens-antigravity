import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_item.dart';
import '../services/auth_service.dart';

/// Provides a stream-based Firebase food repository scoped to the user's household.
final firebaseFoodRepositoryProvider = Provider<FirebaseFoodRepository?>((ref) {
  final householdId = ref.watch(householdIdProvider).value;
  if (householdId == null) return null;
  return FirebaseFoodRepository(FirebaseFirestore.instance, householdId);
});

class FirebaseFoodRepository {
  final FirebaseFirestore _db;
  final String _householdId;

  FirebaseFoodRepository(this._db, this._householdId);

  CollectionReference<Map<String, dynamic>> get _itemsRef =>
      _db.collection('households').doc(_householdId).collection('items');

  /// Real-time stream of all food items, ordered by expiry date.
  Stream<List<FoodItem>> streamItems() {
    return _itemsRef
        .orderBy('expiryDate')
        .snapshots()
        .map((snap) => snap.docs.map(_docToFoodItem).toList());
  }

  /// One-shot fetch of all items.
  Future<List<FoodItem>> getItems() async {
    final snap = await _itemsRef.orderBy('expiryDate').get();
    return snap.docs.map(_docToFoodItem).toList();
  }

  Future<void> addItem(FoodItem item) async {
    await _itemsRef.doc(item.id).set(_foodItemToDoc(item));
  }

  Future<void> updateItem(FoodItem item) async {
    await _itemsRef.doc(item.id).update(_foodItemToDoc(item));
  }

  Future<void> deleteItem(String id) async {
    await _itemsRef.doc(id).delete();
  }

  // ── Serialisation helpers ──────────────────────

  FoodItem _docToFoodItem(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return FoodItem(
      id: doc.id,
      name: d['name'] as String,
      description: d['description'] as String?,
      expiryDate: DateTime.parse(d['expiryDate'] as String),
      expiryType: ExpiryType.values.firstWhere(
        (e) => e.name == d['expiryType'],
        orElse: () => ExpiryType.strict,
      ),
      tags: List<String>.from(d['tags'] ?? []),
      reminders: List<int>.from(d['reminders'] ?? []),
      createdAt: DateTime.parse(d['createdAt'] as String),
    );
  }

  Map<String, dynamic> _foodItemToDoc(FoodItem item) {
    return {
      'name': item.name,
      'description': item.description,
      'expiryDate': item.expiryDate.toIso8601String(),
      'expiryType': item.expiryType.name,
      'tags': item.tags,
      'reminders': item.reminders,
      'createdAt': item.createdAt.toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
