import 'dart:io';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    AndroidInitializationSettings initializationSettingsAndroid = const AndroidInitializationSettings('flutter_logo');

    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    tz.initializeTimeZones();

    await notificationsPlugin.initialize(
      initializationSettings,
    );
  }

  notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails('channelId', 'channelName', importance: Importance.max),
    );
  }

  /*Future showNotification({int id = 0, String? title, String? body, String? payLoad}) async {
    return notificationsPlugin.show(id, title, body, await notificationDetails());
  }*/

  Future showNotification({int id = 0, String? title, String? body, String? payLoad}) async {
    return notificationsPlugin.show(id, title, body, await notificationDetails(), payload: payLoad);
  }

  Future scheduleNotification({
    int id = 0,
    String? title,
    String? body,
    String? payLoad,
    required DateTime scheduledDate,
  }) async {
    await notificationsPlugin.zonedSchedule(
        id, title, body, tz.TZDateTime.from(scheduledDate, tz.local).add(const Duration(seconds: 3)), const NotificationDetails(android: AndroidNotificationDetails('123', 'blog')),
        androidAllowWhileIdle: true, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime);
  }

  Future<void> showGroupedNotifications({
    required String title,
  }) async {
    final platformChannelSpecifics = await notificationDetails();
    final groupedPlatformChannelSpecifics = await groupedNotificationDetails();
    await notificationsPlugin.show(
      0,
      "Team 1",
      "Play Badminton ",
      platformChannelSpecifics,
    );
    await notificationsPlugin.show(
      1,
      "Team 1",
      "Play Volleyball",
      platformChannelSpecifics,
    );
    await notificationsPlugin.show(
      3,
      "Team 1",
      "Play Cricket",
      platformChannelSpecifics,
    );
    await notificationsPlugin.show(
      4,
      "Team 2",
      "Play Badminton",
      Platform.isIOS ? groupedPlatformChannelSpecifics : platformChannelSpecifics,
    );
    await notificationsPlugin.show(
      5,
      "Team 2",
      "Play Volleyball",
      Platform.isIOS ? groupedPlatformChannelSpecifics : platformChannelSpecifics,
    );
    await notificationsPlugin.show(
      6,
      Platform.isIOS ? "Team 2" : "Attention",
      Platform.isIOS ? "Play Cricket" : "5 missed messages",
      groupedPlatformChannelSpecifics,
    );
  }

  Future<NotificationDetails> groupedNotificationDetails() async {
    const List<String> lines = <String>['Team 1 Play Badminton', 'Team 1   Play Volleyball', 'Team 1   Play Cricket', 'Team 2 Play Badminton', 'Team 2   Play Volleyball'];
    const InboxStyleInformation inboxStyleInformation = InboxStyleInformation(lines, contentTitle: '5 messages', summaryText: 'missed messages');
    AndroidNotificationDetails androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'channel id',
      'channel name',
      groupKey: 'com.example.flutter_push_notifications',
      channelDescription: 'channel description',
      setAsGroupSummary: true,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      ticker: 'ticker',
      styleInformation: inboxStyleInformation,
      color: Color(0xff2196f3),
    );

    final details = await notificationsPlugin.getNotificationAppLaunchDetails();
    if (details != null && details.didNotificationLaunchApp) {
      //behaviorSubject.add(details.payload!);
    }

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    return platformChannelSpecifics;
  }
}
