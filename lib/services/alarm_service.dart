import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import '/models/med_model.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  if (response.actionId == 'med_taken') {
    await _decrementQuantity(response.payload);
    await FlutterLocalNotificationsPlugin().cancel(response.id ?? 0);
  }
}

Future<void> _decrementQuantity(String? payload) async {
  if (payload == null) return;
  final id = int.tryParse(payload);
  if (id == null) return;

  final med = await MedicineDatabase.getMedicineById(id);
  if (med == null) return;

  if (med.quantity > 0) {
    final updated = Med(
      id: med.id,
      name: med.name,
      type: med.type,
      color: med.color,
      time: med.time,
      duration: med.duration,
      quantity: med.quantity - 1,  // decrement
      ringtone: med.ringtone,
      repeatReminderTime: med.repeatReminderTime,
      note: med.note,
    );
    await MedicineDatabase.updateMedicine(updated);
  }
}

class AlarmService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> initialize(
      GlobalKey<NavigatorState> navigatorKey) async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) async {
        if (response.actionId == 'med_taken') {
          await _decrementQuantity(response.payload);
          await _notifications.cancel(response.id ?? 0);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    _initialized = true;
  }

  static Future<void> scheduleDailyAlarm({
    required int id,
    required DateTime time,
    required String title,
    required String body,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(time, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'medicine_alarm_channel',
          'Medicine Alarms',
          channelDescription: 'Daily medicine reminders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
          autoCancel: true,
          actions: const [
            AndroidNotificationAction(
              'med_taken',
              'Med Taken ✓',
              cancelNotification: true,
              showsUserInterface: false,
            ),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: id.toString(), // medicine id passed as payload
    );
  }

  static Future<void> cancelAlarm(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllAlarms() async {
    await _notifications.cancelAll();
  }
}