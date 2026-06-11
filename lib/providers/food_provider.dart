import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_item.dart';
import '../repositories/firebase_food_repository.dart';
import '../services/notification_service.dart';

final foodListProvider =
    AsyncNotifierProvider<FoodListNotifier, List<FoodItem>>(() {
  return FoodListNotifier();
});

class FoodListNotifier extends AsyncNotifier<List<FoodItem>> {
  StreamSubscription<List<FoodItem>>? _subscription;

  @override
  FutureOr<List<FoodItem>> build() {
    final repo = ref.watch(firebaseFoodRepositoryProvider);
    if (repo == null) return [];

    // Cancel any previous subscription
    _subscription?.cancel();

    // Listen to Firestore real-time updates
    _subscription = repo.streamItems().listen(
      (items) {
        state = AsyncValue.data(items);
        // Re-schedule notifications for all items on native platforms
        if (!kIsWeb) {
          _rescheduleAllNotifications(items);
        }
      },
      onError: (e, st) {
        state = AsyncValue.error(e, st);
      },
    );

    // Clean up subscription when provider is disposed
    ref.onDispose(() {
      _subscription?.cancel();
    });

    // Return initial empty list; the stream will replace it
    return repo.getItems();
  }

  Future<void> addItem(FoodItem item) async {
    final repo = ref.read(firebaseFoodRepositoryProvider);
    if (repo == null) return;
    await repo.addItem(item);
    // No need to manually update state — Firestore stream handles it
  }

  Future<void> updateItem(FoodItem item) async {
    final repo = ref.read(firebaseFoodRepositoryProvider);
    if (repo == null) return;
    await repo.updateItem(item);
  }

  Future<void> deleteItem(FoodItem item) async {
    final repo = ref.read(firebaseFoodRepositoryProvider);
    if (repo == null) return;
    await repo.deleteItem(item.id);

    // Cancel notifications for this item on native platforms
    if (!kIsWeb) {
      _cancelNotifications(item);
    }
  }

  /// Re-schedule notifications for all items when the stream updates.
  /// Only runs on native platforms (Android/iOS), not web.
  void _rescheduleAllNotifications(List<FoodItem> items) {
    Future(() async {
      try {
        final notifService =
            await ref.read(notificationServiceProvider.future);
        for (final item in items) {
          await notifService.scheduleFoodNotifications(item);
        }
      } catch (e) {
        debugPrint('Notification scheduling error: $e');
      }
    });
  }

  /// Fire-and-forget notification cancellation.
  void _cancelNotifications(FoodItem item) {
    Future(() async {
      try {
        final notifService =
            await ref.read(notificationServiceProvider.future);
        await notifService.cancelNotifications(item);
      } catch (e) {
        debugPrint('Notification cancellation error: $e');
      }
    });
  }
}
