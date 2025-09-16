//Better then below
import 'dart:async';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  static const notificationChannelId = 'location_service_channel';
  static const notificationId = 1;

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    notificationChannelId,
    'Location Service',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: false,
    autoCancel: false,
    ongoing: true,
  );

  static const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  static StreamSubscription<Position>? _positionStreamSubscription;
  static bool _isServiceRunning = false;

  Future<void> startService() async {
    if (_isServiceRunning) {
      // If the service is already running, start the location updates
      final service = FlutterBackgroundService();
      service.invoke('startLocationUpdates');
      return;
    }

    final service = FlutterBackgroundService();

    // Request necessary permissions
    await requestPermissions();

    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    await service.startService();
    _isServiceRunning = true;
  }

  Future<void> stopService() async {
    if (!_isServiceRunning) return;

    final service = FlutterBackgroundService();

    // Invoke the 'stopService' method
    service.invoke('stopService');

    // Wait for the service to stop
    await service.isRunning().then((isRunning) async {
      while (isRunning) {
        await Future.delayed(const Duration(milliseconds: 100));
        isRunning = await service.isRunning();
      }
      _isServiceRunning = false;
    });
  }

  Future<void> requestPermissions() async {
    await Permission.location.request();
    await Permission.locationAlways.request();
    await Permission.locationWhenInUse.request();
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    // Show the notification
    await flutterLocalNotificationsPlugin.show(
      notificationId,
      'Location Service',
      'Fetching location updates',
      platformChannelSpecifics,
    );

    // Handle start location updates event
    service.on('startLocationUpdates').listen((event) async {
      // Start fetching location updates
      _positionStreamSubscription = Geolocator.getPositionStream(
              // desiredAccuracy: LocationAccuracy.best,
              // distanceFilter: 10,
              )
          .listen((Position position) {
        // Send location updates to UI
        service.invoke(
            'update', {'lat': position.latitude, 'lng': position.longitude});
        // Log location updates to console
        print('Location: ${position.latitude}, ${position.longitude}');
      });
    });

    // Handle 'stopService' method invocation
    service.on('stopService').listen((event) async {
      // Cancel the position stream subscription
      await _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;

      // Remove the notification
      await flutterLocalNotificationsPlugin.cancel(notificationId);

      // Stop the location updates
      service.invoke('stopLocationUpdates');

      // Stop the service
      service.stopSelf();
      _isServiceRunning = false;
    });
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    // Show the notification
    await flutterLocalNotificationsPlugin.show(
      notificationId,
      'Location Service',
      'Fetching location updates',
      platformChannelSpecifics,
    );

    // Handle start location updates event
    service.on('startLocationUpdates').listen((event) async {
      // Start fetching location updates
      _positionStreamSubscription = Geolocator.getPositionStream(
              // desiredAccuracy: LocationAccuracy.best,
              )
          .listen((Position position) {
        // Send location updates to UI
        service.invoke(
            'update', {'lat': position.latitude, 'lng': position.longitude});
        // Log location updates to console
        print('Location: ${position.latitude}, ${position.longitude}');
      });
    });

    // Handle 'stopService' method invocation
    service.on('stopService').listen((event) async {
      // Cancel the position stream subscription
      await _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;

      // Remove the notification
      await flutterLocalNotificationsPlugin.cancel(notificationId);

      // Stop the location updates
      service.invoke('stopLocationUpdates');

      // Stop the service
      service.stopSelf();
      _isServiceRunning = false;
    });

    return true;
  }
}


//====================================================================================================================
// //WORKSSSSSSSS. Start and Stop Works (minor bug), Shuts down background service when stop is pressed.
// //Minor bug : The location updates happen/print 4x, i.e same location is printed 4 times
//====================================================================================================================
// import 'dart:async';
// import 'dart:ui';
// import 'package:flutter/widgets.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';

// class LocationService {
//   static final LocationService _instance = LocationService._internal();
//   factory LocationService() => _instance;
//   LocationService._internal();

//   static const notificationChannelId = 'location_service_channel';
//   static const notificationId = 1;

//   static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   static const AndroidNotificationDetails androidPlatformChannelSpecifics =
//       AndroidNotificationDetails(
//     notificationChannelId,
//     'Location Service',
//     importance: Importance.max,
//     priority: Priority.high,
//     showWhen: false,
//     autoCancel: false,
//     ongoing: true,
//   );

//   static const NotificationDetails platformChannelSpecifics =
//       NotificationDetails(android: androidPlatformChannelSpecifics);

//   static StreamSubscription<Position>? _positionStreamSubscription;
//   static bool _isServiceRunning = false;

//   Future<void> startService() async {
//     if (_isServiceRunning) {
//       // If the service is already running, start the location updates
//       final service = FlutterBackgroundService();
//       service.invoke('startLocationUpdates');
//       return;
//     }

//     final service = FlutterBackgroundService();

//     // Request necessary permissions
//     await requestPermissions();

//     await flutterLocalNotificationsPlugin.initialize(
//       const InitializationSettings(
//         android: AndroidInitializationSettings('@mipmap/ic_launcher'),
//       ),
//     );

//     await service.configure(
//       androidConfiguration: AndroidConfiguration(
//         onStart: onStart,
//         autoStart: true,
//         isForegroundMode: true,
//       ),
//       iosConfiguration: IosConfiguration(
//         autoStart: true,
//         onForeground: onStart,
//         onBackground: onIosBackground,
//       ),
//     );

//     await service.startService();
//     _isServiceRunning = true;
//   }

//   Future<void> stopService() async {
//     if (!_isServiceRunning) return;

//     final service = FlutterBackgroundService();

//     // Invoke the 'stopService' method
//     service.invoke('stopService');

//     _isServiceRunning = false;
//   }

//   Future<void> requestPermissions() async {
//     await Permission.location.request();
//     await Permission.locationAlways.request();
//     await Permission.locationWhenInUse.request();
//   }

//   @pragma('vm:entry-point')
//   static void onStart(ServiceInstance service) async {
//     // Show the notification
//     await flutterLocalNotificationsPlugin.show(
//       notificationId,
//       'Location Service',
//       'Fetching location updates',
//       platformChannelSpecifics,
//     );

//     // Handle start location updates event
//     service.on('startLocationUpdates').listen((event) async {
//       // Start fetching location updates
//       _positionStreamSubscription =
//           Geolocator.getPositionStream().listen((Position position) {
//         // Send location updates to UI
//         service.invoke(
//             'update', {'lat': position.latitude, 'lng': position.longitude});
//         // Log location updates to console
//         print('Location: ${position.latitude}, ${position.longitude}');
//       });
//     });

//     // Handle 'stopService' method invocation
//     service.on('stopService').listen((event) async {
//       // Cancel the position stream subscription
//       await _positionStreamSubscription?.cancel();
//       _positionStreamSubscription = null;

//       // Remove the notification
//       await flutterLocalNotificationsPlugin.cancel(notificationId);

//       // Stop the location updates
//       service.invoke('stopLocationUpdates');

//       // Stop the service
//       service.stopSelf();
//       _isServiceRunning = false;
//     });
//   }

//   @pragma('vm:entry-point')
//   static Future<bool> onIosBackground(ServiceInstance service) async {
//     WidgetsFlutterBinding.ensureInitialized();
//     DartPluginRegistrant.ensureInitialized();

//     // Show the notification
//     await flutterLocalNotificationsPlugin.show(
//       notificationId,
//       'Location Service',
//       'Fetching location updates',
//       platformChannelSpecifics,
//     );

//     // Handle start location updates event
//     service.on('startLocationUpdates').listen((event) async {
//       // Start fetching location updates
//       _positionStreamSubscription =
//           Geolocator.getPositionStream().listen((Position position) {
//         // Send location updates to UI
//         service.invoke(
//             'update', {'lat': position.latitude, 'lng': position.longitude});
//         // Log location updates to console
//         print('Location: ${position.latitude}, ${position.longitude}');
//       });
//     });

//     // Handle 'stopService' method invocation
//     service.on('stopService').listen((event) async {
//       // Cancel the position stream subscription
//       await _positionStreamSubscription?.cancel();
//       _positionStreamSubscription = null;

//       // Remove the notification
//       await flutterLocalNotificationsPlugin.cancel(notificationId);

//       // Stop the location updates
//       service.invoke('stopLocationUpdates');

//       // Stop the service
//       service.stopSelf();
//       _isServiceRunning = false;
//     });

//     return true;
//   }
// }

//==================================================================================s
//Start and Stop Location works perfectly. But cant shut down the background service
//==================================================================================
// import 'dart:async';
// import 'dart:ui';
// import 'package:flutter/widgets.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';

// class LocationService {
//   static final LocationService _instance = LocationService._internal();
//   factory LocationService() => _instance;
//   LocationService._internal();

//   static const notificationChannelId = 'location_service_channel';
//   static const notificationId = 1;

//   static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   static const AndroidNotificationDetails androidPlatformChannelSpecifics =
//       AndroidNotificationDetails(
//     notificationChannelId,
//     'Location Service',
//     importance: Importance.max,
//     priority: Priority.high,
//     showWhen: false,
//     autoCancel: false,
//     ongoing: true,
//   );

//   static const NotificationDetails platformChannelSpecifics =
//       NotificationDetails(android: androidPlatformChannelSpecifics);

//   static StreamSubscription<Position>? _positionStreamSubscription;
//   static bool _isServiceRunning = false;

//   Future<void> startService() async {
//     if (_isServiceRunning) {
//       // If the service is already running, start the location updates
//       FlutterBackgroundService().invoke('startLocationUpdates');
//       return;
//     }

//     final service = FlutterBackgroundService();

//     // Request necessary permissions
//     await requestPermissions();

//     await flutterLocalNotificationsPlugin.initialize(
//       const InitializationSettings(
//         android: AndroidInitializationSettings('@mipmap/ic_launcher'),
//       ),
//     );

//     await service.configure(
//       androidConfiguration: AndroidConfiguration(
//         onStart: onStart,
//         autoStart: true,
//         isForegroundMode: true,
//       ),
//       iosConfiguration: IosConfiguration(
//         autoStart: true,
//         onForeground: onStart,
//         onBackground: onIosBackground,
//       ),
//     );

//     await service.startService();
//     _isServiceRunning = true;
//   }

//   Future<void> stopService() async {
//     if (!_isServiceRunning) return;

//     // Stop the location updates
//     FlutterBackgroundService().invoke('stopLocationUpdates');
//   }

//   Future<void> requestPermissions() async {
//     await Permission.location.request();
//     await Permission.locationAlways.request();
//     await Permission.locationWhenInUse.request();
//   }

//   @pragma('vm:entry-point')
//   static void onStart(ServiceInstance service) async {
//     // Show the notification
//     await flutterLocalNotificationsPlugin.show(
//       notificationId,
//       'Location Service',
//       'Fetching location updates',
//       platformChannelSpecifics,
//     );

//     // Handle start location updates event
//     service.on('startLocationUpdates').listen((event) async {
//       // Start fetching location updates
//       _positionStreamSubscription =
//           Geolocator.getPositionStream().listen((Position position) {
//         // Send location updates to UI
//         service.invoke(
//             'update', {'lat': position.latitude, 'lng': position.longitude});
//         // Log location updates to console
//         print('Location: ${position.latitude}, ${position.longitude}');
//       });
//     });

//     // Handle stop location updates event
//     service.on('stopLocationUpdates').listen((event) async {
//       // Cancel the position stream subscription
//       await _positionStreamSubscription?.cancel();
//       _positionStreamSubscription = null;
//     });
//   }

//   @pragma('vm:entry-point')
//   static Future<bool> onIosBackground(ServiceInstance service) async {
//     WidgetsFlutterBinding.ensureInitialized();
//     DartPluginRegistrant.ensureInitialized();

//     // Show the notification
//     await flutterLocalNotificationsPlugin.show(
//       notificationId,
//       'Location Service',
//       'Fetching location updates',
//       platformChannelSpecifics,
//     );

//     // Handle start location updates event
//     service.on('startLocationUpdates').listen((event) async {
//       // Start fetching location updates
//       _positionStreamSubscription =
//           Geolocator.getPositionStream().listen((Position position) {
//         // Send location updates to UI
//         service.invoke(
//             'update', {'lat': position.latitude, 'lng': position.longitude});
//         // Log location updates to console
//         print('Location: ${position.latitude}, ${position.longitude}');
//       });
//     });

//     // Handle stop location updates event
//     service.on('stopLocationUpdates').listen((event) async {
//       // Cancel the position stream subscription
//       await _positionStreamSubscription?.cancel();
//       _positionStreamSubscription = null;
//     });

//     return true;
//   }
// }

//Unable to stop 'service' cause its not an option for our plugin lol
// import 'dart:async';
// import 'dart:ui';
// import 'package:flutter/widgets.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';

// class LocationService {
//   static final LocationService _instance = LocationService._internal();
//   factory LocationService() => _instance;
//   LocationService._internal();

//   static const notificationChannelId = 'location_service_channel';
//   static const notificationId = 1;

//   static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   static const AndroidNotificationDetails androidPlatformChannelSpecifics =
//       AndroidNotificationDetails(
//     notificationChannelId,
//     'Location Service',
//     importance: Importance.max,
//     priority: Priority.high,
//     showWhen: false,
//     autoCancel: false,
//     ongoing: true,
//   );

//   static const NotificationDetails platformChannelSpecifics =
//       NotificationDetails(android: androidPlatformChannelSpecifics);

//   static StreamSubscription<Position>? _positionStreamSubscription;
//   static bool _isServiceRunning = false;

//   Future<void> startService() async {
//     if (_isServiceRunning) return;

//     final service = FlutterBackgroundService();

//     // Request necessary permissions
//     await requestPermissions();

//     await flutterLocalNotificationsPlugin.initialize(
//       const InitializationSettings(
//         android: AndroidInitializationSettings('@mipmap/ic_launcher'),
//       ),
//     );

//     await service.configure(
//       androidConfiguration: AndroidConfiguration(
//         onStart: onStart,
//         autoStart: true,
//         isForegroundMode: true,
//       ),
//       iosConfiguration: IosConfiguration(
//         autoStart: true,
//         onForeground: onStart,
//         onBackground: onIosBackground,
//       ),
//     );

//     await service.startService();
//     _isServiceRunning = true;
//   }

//   Future<void> stopService() async {
//     if (!_isServiceRunning) return;

//     final service = FlutterBackgroundService();

//     // Cancel the position stream subscription
//     await _positionStreamSubscription?.cancel();
//     _positionStreamSubscription = null;

//     // Remove the notification
//     await flutterLocalNotificationsPlugin.cancel(notificationId);

//     // Stop the service
//     service.invoke('stopService');
//     _isServiceRunning = false;
//   }

//   Future<void> requestPermissions() async {
//     await Permission.location.request();
//     await Permission.locationAlways.request();
//     await Permission.locationWhenInUse.request();
//   }

//   @pragma('vm:entry-point')
//   static void onStart(ServiceInstance service) async {
//     // Show the notification
//     await flutterLocalNotificationsPlugin.show(
//       notificationId,
//       'Location Service',
//       'Fetching location updates',
//       platformChannelSpecifics,
//     );

//     // Start fetching location updates
//     _positionStreamSubscription =
//         Geolocator.getPositionStream().listen((Position position) {
//       // Send location updates to UI
//       service.invoke(
//           'update', {'lat': position.latitude, 'lng': position.longitude});
//       // Log location updates to console
//       print('Location: ${position.latitude}, ${position.longitude}');
//     });

//     // Handle stop event
//     service.on('stopService').listen((event) async {
//       // Cancel the position stream subscription
//       await _positionStreamSubscription?.cancel();
//       _positionStreamSubscription = null;

//       // Remove the notification
//       await flutterLocalNotificationsPlugin.cancel(notificationId);

//       // Stop the service
//       service.invoke('stopService');
//       _isServiceRunning = false;
//     });
//   }

//   @pragma('vm:entry-point')
//   static Future<bool> onIosBackground(ServiceInstance service) async {
//     WidgetsFlutterBinding.ensureInitialized();
//     DartPluginRegistrant.ensureInitialized();

//     // Show the notification
//     await flutterLocalNotificationsPlugin.show(
//       notificationId,
//       'Location Service',
//       'Fetching location updates',
//       platformChannelSpecifics,
//     );

//     // Start fetching location updates
//     _positionStreamSubscription =
//         Geolocator.getPositionStream().listen((Position position) {
//       // Send location updates to UI
//       service.invoke(
//           'update', {'lat': position.latitude, 'lng': position.longitude});
//       // Log location updates to console
//       print('Location: ${position.latitude}, ${position.longitude}');
//     });

//     // Handle stop event
//     service.on('stopService').listen((event) async {
//       // Cancel the position stream subscription
//       await _positionStreamSubscription?.cancel();
//       _positionStreamSubscription = null;

//       // Remove the notification
//       await flutterLocalNotificationsPlugin.cancel(notificationId);

//       // Stop the service
//       service.invoke('stopService');
//       _isServiceRunning = false;
//     });

//     return true;
//   }
// }

//Works and stops location service, But cant restart location
// import 'dart:async';
// import 'dart:ui';
// import 'package:flutter/widgets.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';

// class LocationService {
//   static final LocationService _instance = LocationService._internal();
//   factory LocationService() => _instance;
//   LocationService._internal();

//   static const notificationChannelId = 'location_service_channel';
//   static const notificationId = 1;

//   static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   static const AndroidNotificationDetails androidPlatformChannelSpecifics =
//       AndroidNotificationDetails(
//     notificationChannelId,
//     'Location Service',
//     importance: Importance.max,
//     priority: Priority.high,
//     showWhen: false,
//     autoCancel: false,
//     ongoing: true,
//   );

//   static const NotificationDetails platformChannelSpecifics =
//       NotificationDetails(android: androidPlatformChannelSpecifics);

//   static StreamSubscription<Position>? _positionStreamSubscription;

//   Future<void> startService() async {
//     final service = FlutterBackgroundService();

//     // Request necessary permissions
//     await requestPermissions();

//     await flutterLocalNotificationsPlugin.initialize(
//       const InitializationSettings(
//         android: AndroidInitializationSettings('@mipmap/ic_launcher'),
//       ),
//     );

//     await service.configure(
//       androidConfiguration: AndroidConfiguration(
//         onStart: onStart,
//         autoStart: true,
//         isForegroundMode: true,
//       ),
//       iosConfiguration: IosConfiguration(
//         autoStart: true,
//         onForeground: onStart,
//         onBackground: onIosBackground,
//       ),
//     );

//     await service.startService();
//   }

//   Future<void> stopService() async {
//     final service = FlutterBackgroundService();

//     // Cancel the position stream subscription
//     await _positionStreamSubscription?.cancel();
//     _positionStreamSubscription = null;

//     // Remove the notification
//     await flutterLocalNotificationsPlugin.cancel(notificationId);

//     // Stop the service
//     service.invoke('stopService');
//   }

//   Future<void> requestPermissions() async {
//     await Permission.location.request();
//     await Permission.locationAlways.request();
//     await Permission.locationWhenInUse.request();
//   }

//   @pragma('vm:entry-point')
//   static void onStart(ServiceInstance service) async {
//     // Show the notification
//     await flutterLocalNotificationsPlugin.show(
//       notificationId,
//       'Location Service',
//       'Fetching location updates',
//       platformChannelSpecifics,
//     );

//     // Start fetching location updates
//     _positionStreamSubscription =
//         Geolocator.getPositionStream().listen((Position position) {
//       // Send location updates to UI
//       service.invoke(
//           'update', {'lat': position.latitude, 'lng': position.longitude});
//       // Log location updates to console
//       print('Location: ${position.latitude}, ${position.longitude}');
//     });

//     // Handle stop event
//     service.on('stopService').listen((event) async {
//       // Cancel the position stream subscription
//       await _positionStreamSubscription?.cancel();
//       _positionStreamSubscription = null;

//       // Remove the notification
//       await flutterLocalNotificationsPlugin.cancel(notificationId);

//       // Stop the service
//       service.invoke('stopService');
//     });
//   }

//   @pragma('vm:entry-point')
//   static Future<bool> onIosBackground(ServiceInstance service) async {
//     WidgetsFlutterBinding.ensureInitialized();
//     DartPluginRegistrant.ensureInitialized();

//     // Show the notification
//     await flutterLocalNotificationsPlugin.show(
//       notificationId,
//       'Location Service',
//       'Fetching location updates',
//       platformChannelSpecifics,
//     );

//     // Start fetching location updates
//     _positionStreamSubscription =
//         Geolocator.getPositionStream().listen((Position position) {
//       // Send location updates to UI
//       service.invoke(
//           'update', {'lat': position.latitude, 'lng': position.longitude});
//       // Log location updates to console
//       print('Location: ${position.latitude}, ${position.longitude}');
//     });

//     // Handle stop event
//     service.on('stopService').listen((event) async {
//       // Cancel the position stream subscription
//       await _positionStreamSubscription?.cancel();
//       _positionStreamSubscription = null;

//       // Remove the notification
//       await flutterLocalNotificationsPlugin.cancel(notificationId);

//       // Stop the service
//       service.invoke('stopService');
//     });

//     return true;
//   }
// }
