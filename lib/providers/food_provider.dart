import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_item.dart';
import '../repositories/food_repository.dart';
import '../services/notification_service.dart';

final foodListProvider = AsyncNotifierProvider<FoodListNotifier, List<FoodItem>>(() {
  return FoodListNotifier();
});

class FoodListNotifier extends AsyncNotifier<List<FoodItem>> {
  @override
  FutureOr<List<FoodItem>> build() async {
    final repo = await ref.read(asyncFoodRepositoryProvider.future);
    return await repo.getItems();
  }

  Future<void> addItem(FoodItem item) async {
    final repo = await ref.read(asyncFoodRepositoryProvider.future);
    await repo.addItem(item);

    // Refresh the list from DB immediately so the UI updates
    final items = await repo.getItems();
    state = AsyncValue.data(items);

    // Schedule notifications in the background (fire-and-forget)
    _scheduleNotifications(item);
  }

  Future<void> updateItem(FoodItem item) async {
    final repo = await ref.read(asyncFoodRepositoryProvider.future);
    await repo.updateItem(item);

    final items = await repo.getItems();
    state = AsyncValue.data(items);

    _scheduleNotifications(item);
  }

  Future<void> deleteItem(FoodItem item) async {
    final repo = await ref.read(asyncFoodRepositoryProvider.future);
    await repo.deleteItem(item.id);

    final items = await repo.getItems();
    state = AsyncValue.data(items);

    _cancelNotifications(item);
  }

  /// Fire-and-forget notification scheduling — never blocks the UI.
  void _scheduleNotifications(FoodItem item) {
    Future(() async {
      try {
        final notifService = await ref.read(notificationServiceProvider.future);
        await notifService.scheduleFoodNotifications(item);
      } catch (e) {
        debugPrint('Notification scheduling error: $e');
      }
    });
  }

  /// Fire-and-forget notification cancellation.
  void _cancelNotifications(FoodItem item) {
    Future(() async {
      try {
        final notifService = await ref.read(notificationServiceProvider.future);
        await notifService.cancelNotifications(item);
      } catch (e) {
        debugPrint('Notification cancellation error: $e');
      }
    });
  }
}
