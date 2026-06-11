import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/food_item.dart';
import 'preferences_service.dart';
import 'timezone_helper.dart'
    if (dart.library.html) 'timezone_helper_web.dart' as tz_helper;

final notificationServiceProvider =
    FutureProvider<NotificationService>((ref) async {
  final prefs = ref.watch(preferencesServiceProvider);
  final service = NotificationService(prefs);
  await service.init();
  return service;
});

class NotificationService {
  final PreferencesService _prefs;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  NotificationService(this._prefs);

  Future<void> init() async {
    if (kIsWeb) return;

    tz.initializeTimeZones();
    final tzName = await tz_helper.getLocalTimezoneName();
    tz.setLocalLocation(tz.getLocation(tzName));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await _plugin.initialize(settings: initializationSettings);
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final bool? result =
            await androidImpl.requestNotificationsPermission();
        await androidImpl.requestExactAlarmsPermission();
        return result ?? false;
      }

      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        final bool? result = await iosImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return result ?? false;
      }
    } catch (e) {
      // Platform not supported
    }
    return false;
  }

  int _generateIdForNotification(String uuid, int days) {
    return (uuid.hashCode + days.hashCode).abs();
  }

  Future<void> scheduleFoodNotifications(FoodItem item) async {
    if (kIsWeb) return;
    await cancelNotifications(item);

    final notificationTime = _prefs.notificationTime;

    for (int daysBefore in item.reminders) {
      var notifyDate = item.expiryDate.subtract(Duration(days: daysBefore));
      var scheduledDate = DateTime(
        notifyDate.year,
        notifyDate.month,
        notifyDate.day,
        notificationTime.hour,
        notificationTime.minute,
      );

      if (scheduledDate.isBefore(DateTime.now())) continue;

      int id = _generateIdForNotification(item.id, daysBefore);
      String title = daysBefore == 0
          ? "Scadenza in arrivo!"
          : "Scadenza vicina per ${item.name}";
      String body = daysBefore == 0
          ? "${item.name} scade oggi (${item.expiryType.label.toLowerCase()})"
          : "${item.name} scade tra $daysBefore giorni";

      tz.TZDateTime scheduledTZDate =
          tz.TZDateTime.from(scheduledDate, tz.local);

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'dispens_expiries',
        'Scadenze alimenti',
        channelDescription: 'Notifiche per la scadenza degli alimenti',
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails notifDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledTZDate,
        notificationDetails: notifDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelNotifications(FoodItem item) async {
    if (kIsWeb) return;
    for (final days in item.reminders) {
      int id = _generateIdForNotification(item.id, days);
      await _plugin.cancel(id: id);
    }
  }
}
