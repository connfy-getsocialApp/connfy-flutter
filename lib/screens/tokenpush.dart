import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart';

import '../helper/firebase_notification_handler.dart';

class Token extends StatefulWidget {
  const Token({super.key});

  @override
  State<Token> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<Token> {
  FirebaseNotificationHandler firebaseNotificationHandler = FirebaseNotificationHandler();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      initNotification();
    });
  }

  Future<void> initNotification() async {
    await firebaseNotificationHandler.initialize(context);
    await firebaseNotificationHandler.subscribeToTopic('TopicName');
    firebaseNotificationHandler.getToken().then((value) {
      log(value ?? '');
    });

    firebaseNotificationHandler.onTokenRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Firebase Push Notification'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            firebaseNotificationHandler.getToken().then((String? value) async {
              Map<String, dynamic> requestBody = {
                'to': '$value',
                'priority': 'high',
                'notification': {
                  'title': 'This is Title',
                  'body': 'This is Body',
                },
                'data': {'type': 'msg'},
              };
              await post(
                Uri.parse('https://fcm.googleapis.com/fcm/send'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'key=AAAAr-YtR_8:APA91bFluLRwajp5TKC4ZpNNnjX36hdW8g3Fg_gS31R8__i2XZmiuT4glUcI3PiD-8UPSumBVxrrcvT4uHYl3_49O3VCnxbnRmJubXk0h93nrvKMFcVwHhxEPoCocHHUqFJ_u1ISqxN-',
                },
                body: jsonEncode(requestBody),
              );
            });
          },
          child: const Text('Flutter Firebase Push Notification'),
        ),
      ),
    );
  }
}
