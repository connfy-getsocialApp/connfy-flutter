import 'dart:async';

import 'package:chatapp/screens/ChatProvider.dart';
import 'package:chatapp/screens/NetworkService.dart';
import 'package:chatapp/screens/splash_screen.dart';
import 'package:chatapp/util/content_filter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:localstorage/localstorage.dart';

import 'package:provider/provider.dart';

import 'constants/NotificationService.dart';

const taskName = "first-task";

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a foreground message: ${message.messageId}');
  print('Notification Message: ${message.data}');

  final data = message.data;
  final title = data['title'] ?? '';
  final body = data['body'] ?? '';
  final imageUrl = data['image'] ?? '';
  if (imageUrl.isNotEmpty) {
    // Show notification dialog if image URL is provided

    await NotificationService()
        .showNotificationWithImage(title, body, imageUrl);
  } else if (title.isNotEmpty) {
    if (title.toString().contains('Message from:')) {
    } else {
      NotificationService().showNotification(title: title, body: body);
    }
  }
  await initLocalStorage();

  print("Handling a background message: ${message.messageId}");
}

void notificationTapBackground(NotificationResponse notificationResponse) {
  // print('notification(${notificationResponse.id}) action tapped: '
  //     '${notificationResponse.actionId} with'
  //     ' payload: ${notificationResponse.payload}');
  if (notificationResponse.input?.isNotEmpty ?? false) {
    // print(
    //     'notification action tapped with input: ${notificationResponse.input}');
  }
  // print('Notification tapped in background');
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseMessaging.instance.requestPermission();
  await ContentFilter().initialize();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ReviewModeProvider()),

        ChangeNotifierProvider(create: (_) => NetworkService()),
        ChangeNotifierProvider<ChatProvider>(create: (_) => ChatProvider())
      ],
      child: const MyApp(),
    ),
  );

// initializeService();
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? userIsLoggedIn = false;

  @override
  void initState() {
    super.initState();
    initLocalStorage();
    //schedulePeriodicTask();
    ///retrive();

    // Example CET time
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme appColors = ColorScheme.fromSeed(
      seedColor: Colors.blue,
    );
    // print(DateFormat('yyy-MM-dd HH:mm:ss ').format(DateTime.now()));
    return MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Connfy',
        theme: ThemeData(
          // useMaterial3: false,
          primaryColor: Colors.blue,
          // colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(secondary: Colors.blueAccent),
          // hintColor: Colors.blueAccent,
        ),
        /*   home: ThankYouPage(
          title: '',
        ));*/
        home: SplashScreen());
  }
}
class ReviewModeProvider with ChangeNotifier {
  bool _isReviewMode = false;

  bool get isReviewMode => _isReviewMode;

  void enableReviewMode() {
    _isReviewMode = true;
    notifyListeners();
  }

  void disableReviewMode() {
    _isReviewMode = false;
    notifyListeners();
  }
}
