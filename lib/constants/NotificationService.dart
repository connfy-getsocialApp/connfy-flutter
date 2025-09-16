import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static final NotificationService _notificationService = NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /* Future<void> showNotificationDialog(String title, String body) async {
    showDialog(
      context: navigatorKey.currentState!.overlay!.context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }*/
  Future<void> showNotificationDialog(String title, String body, String imageUrl) async {
    showDialog(
      context: navigatorKey.currentState!.overlay!.context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8, // Set a finite width for the content
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (imageUrl.isNotEmpty)
                  FutureBuilder(
                    future: precacheImage(NetworkImage(imageUrl), context),
                    builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 100, // Placeholder height
                          child: Center(
                              child: Center(
                                  child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xff03A0E3)),
                          ))),
                        );
                      } else {
                        return Image.network(
                          imageUrl,
                          height: 100, // Adjust height as needed
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      }
                    },
                  ),
                Text(body),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> showNotification({required String title, required String body}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'flutter_notification',
      'Flutter Notification',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  Future<void> showNotificationWithImage(String title, String body, String imageUrl) async {
    print('Requesting image from URL: $imageUrl');
    try {
      final http.Response response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        print('Image downloaded successfully');
        final Uint8List imageData = response.bodyBytes;

        try {
          final ByteArrayAndroidBitmap bigPicture = ByteArrayAndroidBitmap.fromBase64String(base64Encode(imageData));

          final BigPictureStyleInformation bigPictureStyleInformation = BigPictureStyleInformation(
            bigPicture,
            contentTitle: title,
            summaryText: body,
          );

          final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
            'flutter_notification',
            'Flutter Notification',
            importance: Importance.max,
            priority: Priority.high,
            styleInformation: bigPictureStyleInformation,
          );

          final NotificationDetails notificationDetails = NotificationDetails(
            android: androidDetails,
          );

          await flutterLocalNotificationsPlugin.show(
            0,
            title,
            body,
            notificationDetails,
          );

          print('Notification sent with image');
        } catch (e) {
          print('Error processing image for notification: $e');
          await showNotification(title: title, body: body);
        }
      } else {
        print('Error downloading image: ${response.statusCode}');
        await showNotification(title: title, body: body);
      }
    } catch (e) {
      print('Error during HTTP request: $e');
      await showNotification(title: title, body: body);
    }
  }
}
