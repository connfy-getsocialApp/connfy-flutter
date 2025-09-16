import 'dart:developer';
import 'dart:math' as math;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../screens/chatlistnew.dart';

class FirebaseNotificationHandler {
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize(BuildContext context) async {
    NotificationSettings notificationSettings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    //? This code will be executed when the app is opened through the
    //? notification displayed in the notification tray while the app is closed/killed.
    RemoteMessage? message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      log('Got a message ---- (getInitialMessage) ----');
      log('Message Data: ${message.data}');
      if (message.notification != null) {
        log('Message Notification: ${message.notification}');
        log('Notification Title: ${message.notification?.title ?? 'Empty title'}');
        log('Notification Body: ${message.notification?.body ?? 'Empty body'}');

        Future.delayed(Duration.zero, () {
          if (message.data['msg'] == 'test message') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (cntxt) => ChatListnew(""
                    // info: message.data['msg'],
                    ),
              ),
            );
          }
        });
      }
    }

    //? when app is Foreground, that	means application is open,
    //? in view and in use this code is execute. At this time Notifications
    //?  will not appear in the notification tray.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Got a message whilst in the foreground!---- (onMessage) ----');
      log('Message Data: ${message.data}');
      if (message.notification != null) {
        log('Message Notification: ${message.notification}');
        log('Notification Title: ${message.notification?.title ?? 'Empty title'}');
        log('Notification Body: ${message.notification?.body ?? 'Empty body'}');
        initFlutterLocalNotificationsPlugin(context, message);
        showLocalNotification(message);
      }
    });

    //? When the app is in the background, meaning the app is not visible. This
    //? code will be executed when notifications appear in the notification tray.
    FirebaseMessaging.onBackgroundMessage(firebaseMessingBackgroundHandler);

    //? This code is executed when the notification is appear in the
    //? notification tray when the app is in Background and the app is
    //? opened with the notification On Tap.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('This App is opened by the Notification Tap ---- (onMessageOpenedApp) ----');
      log('Message Data: ${message.data}');
      if (message.notification != null) {
        log('Message Notification: ${message.notification}');
        log('Notification Title: ${message.notification?.title ?? 'Empty title'}');
        log('Notification Body: ${message.notification?.body ?? 'Empty body'}');
      }
    });
  }

  Future<void> initFlutterLocalNotificationsPlugin(BuildContext context, RemoteMessage message) async {
    //? iniatialize the Flutter-Local-Notifications settings for android and iOS.
    AndroidInitializationSettings androidInitializationSettings = const AndroidInitializationSettings('@mipmap/ic_launcher');
    DarwinInitializationSettings iosInitializationSettings = const DarwinInitializationSettings();

    InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        log('------------------');
        log(details.id.toString());
        log(message.data.toString());
        if (message.data['msg'] == 'test message') {
          /*   Navigator.push(
            context,
            MaterialPageRoute(
              builder: (cntxt) => SecondScreen(
                info: message.data['msg'],
              ),
            ),
          );*/
        }
      },
    );
  }

  Future<void> showLocalNotification(RemoteMessage message) async {
    //? iniatialize Android Notification Channel for the Flutter-Local-Notifications.
    AndroidNotificationChannel androidNotificationChannel = AndroidNotificationChannel(
      math.Random.secure().nextInt(10000).toString(),
      'High Importance Notification',
      importance: Importance.max,
    );

    AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      androidNotificationChannel.id,
      androidNotificationChannel.name,
      channelDescription: 'Channel description',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );

    DarwinNotificationDetails iosNotificationDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    //? Show the Flutter-Local-Notifications.
    Future.delayed(
      Duration.zero,
      () {
        _flutterLocalNotificationsPlugin.show(
          0,
          message.notification?.title ?? 'Empty Title',
          message.notification?.body ?? 'Empty Body',
          notificationDetails,
        );
      },
    );
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  void onTokenRefresh() async {
    //? when token is refreshed.
    _firebaseMessaging.onTokenRefresh.listen((String token) {
      log('Send refresh token to api : $token');
    });
  }

  Future<void> subscribeToTopic(String topicName) async {
    //?  to achieve Topic-Based-Notification, subscribe To Topic.
    await _firebaseMessaging.subscribeToTopic(topicName);
  }

  Future<void> unsubscribeFromTopic(String topicName) async {
    //?  Unsubscribe From Topic.
    await _firebaseMessaging.unsubscribeFromTopic(topicName);
  }
}

//? Top label function
Future<void> firebaseMessingBackgroundHandler(RemoteMessage message) async {
  log('Top Label Function. ---- (onBackgroundMessage) ----');
  log('Message Data: ${message.data}');
  if (message.notification != null) {
    log('Message Notification: ${message.notification}');
    log('Notification Title: ${message.notification?.title ?? 'Empty title'}');
    log('Notification Body: ${message.notification?.body ?? 'Empty body'}');
  }
}
