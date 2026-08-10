import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  if (response.actionId == 'med_taken') {
    await _decrementQuantityBackground(response.payload);
    await FlutterLocalNotificationsPlugin().cancel(response.id ?? 0);
  }
}

@pragma('vm:entry-point')
Future<void> _decrementQuantityBackground(String? payload) async {
  if (payload == null) return;
  final id = int.tryParse(payload);
  if (id == null) return;

  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'medicines.db');
  final db = await openDatabase(path);

  final maps = await db.query(
    'medicines',
    where: 'id = ?',
    whereArgs: [id],
  );

  if (maps.isEmpty) {
    await db.close();
    return;
  }

  final quantity = maps.first['quantity'] as int;
  if (quantity > 0) {
    await db.update(
      'medicines',
      {'quantity': quantity - 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  await db.close();
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
          await _decrementQuantityBackground(response.payload);
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