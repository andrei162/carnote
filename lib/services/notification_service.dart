import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:intl/intl.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
    InitializationSettings(android: androidInit);

    await _notificationsPlugin.initialize(initSettings);

    // Timezone init
    tz.initializeTimeZones();
  }

  static Future<void> showDocumentNotification({
    required int id,
    required String title,
    required DateTime expiryDate,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'document_channel',
      'Document Notifications',
      channelDescription: 'Notifies about expiring documents',
      importance: Importance.max,
      priority: Priority.high,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id,
      'Document Expiry Reminder',
      '$title expires on ${DateFormat.yMMMMd().format(expiryDate)}',
      notificationDetails,
    );
  }

}
