//Better then below
import 'dart:async';
import 'dart:convert';
// import 'dart:developer';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:localstorage/localstorage.dart';

import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/database.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  static const notificationChannelId = 'location_service_channel';
  static const notificationId = 1;

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /* static const AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails(
    notificationChannelId,
    'Location Service',
    importance: Importance.max,
    priority: Priority.max,
    showWhen: false,
    autoCancel: false,
    ongoing: true,
  );*/

  /* static const NotificationDetails platformChannelSpecifics =
  NotificationDetails(android: androidPlatformChannelSpecifics);*/

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

    /*  await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );*/

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: false,
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
        await Future.delayed(const Duration(seconds: 120));
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
    /*  await flutterLocalNotificationsPlugin.show(
      notificationId,
      'Location Service',
      'Fetching location updates',
      platformChannelSpecifics,
    );*/

    // Initialize a periodic timer
    Timer? periodicTimer;
    periodicTimer =
        Timer.periodic(const Duration(minutes: 10), (Timer timer) async {
      final NetworkInfo networkInfo = NetworkInfo();
      try {
        String? wifiName = await networkInfo.getWifiName();
        String? wifiBSSID = await networkInfo.getWifiBSSID();

        // print('Wi-Fi Name: $wifiName');
        // print('Wi-Fi BSSID: $wifiBSSID');
        service.invoke(
            'wifiUpdate', {'wifiName': wifiName, 'wifiBSSID': wifiName});
        await wificheck(wifiName!);
      } catch (e) {
        await wificheck("wifiName!");
        // print('Failed to get Wi-Fi information: $e');
      }
      // Fetch and log location updates every 10 seconds
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );
        // Send location updates to UI
        service.invoke(
            'update', {'lat': position.latitude, 'lng': position.longitude});

        // Log location updates to console
        // print('Location: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        // print('Failed to get current position: $e');
      }

      // Example: Stop periodic updates if a certain condition is met
      // if (someCondition) {
      //   periodicTimer?.cancel();
      // }
    });

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
        // print('Location: ${position.latitude}, ${position.longitude}');
      });
    });

    // Handle 'stopService' method invocation
    service.on('stopService').listen((event) async {
      // Cancel the position stream subscription
      await _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;

      // Cancel the periodic timer
      periodicTimer?.cancel();

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
    Timer? periodicTimer;
    periodicTimer =
        Timer.periodic(const Duration(minutes: 10), (Timer timer) async {
      final NetworkInfo networkInfo = NetworkInfo();
      try {
        String? wifiName = await networkInfo.getWifiName();
        String? wifiBSSID = await networkInfo.getWifiBSSID();

        // print('Wi-Fi Name: $wifiName');
        // print('Wi-Fi BSSID: $wifiBSSID');
        service.invoke(
            'wifiUpdate', {'wifiName': wifiName, 'wifiBSSID': wifiName});
        await wificheck(wifiName!);
      } catch (e) {
        await wificheck("wifiName!");
        // print('Failed to get Wi-Fi information: $e');
      }
      // Fetch and log location updates every 10 seconds
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );
        // Send location updates to UI
        service.invoke(
            'update', {'lat': position.latitude, 'lng': position.longitude});

        // Log location updates to console
        // print('Location: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        // print('Failed to get current position: $e');
      }

      // Example: Stop periodic updates if a certain condition is met
      // if (someCondition) {
      //   periodicTimer?.cancel();
      // }
    });

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
        // print('Location: ${position.latitude}, ${position.longitude}');
      });
    });

    // Handle 'stopService' method invocation
    /*service.on('stopService').listen((event) async {
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
    });*/

    return true;
  }
}

/*wificheck(String? ssid) async {
  String wifiName = ssid!.replaceAll('"', '') ?? '';
  var headers = {'Content-Type': 'application/json'};
  var request = http.Request('POST', Uri.parse('https://connfy.ragutis.com/api/wifi_check'));
  request.body = json.encode({"ssid": wifiName});
  //   Fluttertoast.showToast(msg: request.body.toString(), toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, textColor: Colors.white, fontSize: 16.0);

  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    String jsonData = await response.stream.bytesToString();
    Map<String, dynamic> responseData = jsonDecode(jsonData);
    print(responseData);

    if (responseData.containsKey('data')) {
      int status = responseData['status_match'];

      if (status == 1) {
        String shopid = responseData['shop_id'].toString();
        print('shopid $shopid');




        //  Fluttertoast.showToast(msg: 'WIFI MATCH: $status\n', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, textColor: Colors.white, fontSize: 16.0);
        // String? wifiName = ssidnew;

      } else {

        //  Fluttertoast.showToast(msg: 'WIFI NOT MATCH: $status\n', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, textColor: Colors.white, fontSize: 16.0);

      }
    } else {

    }
  } else {

    print(response.reasonPhrase);
  }
}*/

wificheck(String? ssid) async {
  String wifiName = ssid!.replaceAll('"', '') ?? '';
  var headers = {'Content-Type': 'application/json'};
  var request = http.Request('POST',
      Uri.parse('https://admin.connfy.at/api/wifi_check'));
  request.body = json.encode({"ssid": wifiName});
  //   Fluttertoast.showToast(msg: request.body.toString(), toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, textColor: Colors.white, fontSize: 16.0);

  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    String jsonData = await response.stream.bytesToString();
    Map<String, dynamic> responseData = jsonDecode(jsonData);
    // print(responseData);

    if (responseData.containsKey('data')) {
      int status = responseData['status_match'];

      if (status == 1) {
        String shopid = responseData['shop_id'].toString();
        // print('shopid $shopid');
        //   localStorage.setItem('wifiName', wifiName);
        //  localStorage.setItem('shopidn', shopid);
        //callUpdate(responseData['shop_id']);

        sendStatusToServer(shopid, 1);
        // _updateUserStatus(1);
        //  Fluttertoast.showToast(msg: 'WIFI MATCH: $status\n', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, textColor: Colors.white, fontSize: 16.0);
        // String? wifiName = ssidnew;
      } else {
        sendStatusToServer("", 0);
        //_updateUserStatus(0);
        //  Fluttertoast.showToast(msg: 'WIFI NOT MATCH: $status\n', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, textColor: Colors.white, fontSize: 16.0);
      }
    } else {
      sendStatusToServer("", 0);
      //  _updateUserStatus(0);
    }
  } else {
    sendStatusToServer("", 0);
    // _updateUserStatus(0);

    print(response.reasonPhrase);
  }
}

sendStatusToServer(String shopId, dynamic status) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String UserId =
      prefs.getString('UserId') ?? ''; // Replace with your server URL
  try {
    var headers = {
      'Authorization':
          'key=AAAAGLDkAjg:APA91bFsO9qoCm-dYTaDicJ9cHDsg8ur4HY-dqx2tRzSJrh1X7Lxg0c0pZrBEfSSnRoOHdAMUMuRe59YnWkKXFMA3BOTw5QLAqhXzUe_MQ6Bsuu71RvxGkJ5l23obQBayyOyLRJzXYk1',
      'Content-Type': 'application/json'
    };
    var request = http.Request(
        'POST',
        Uri.parse(
            'https://admin.connfy.at/api/check_user_status'));
    request.body = json.encode({
      "user_id": UserId,
      "shop_id": shopId,
      "status": status,
      "connected_time": DateFormat('yyy-MM-dd HH:mm:ss').format(DateTime.now())
    });
    request.headers.addAll(headers);
    // print(request.body);
    http.StreamedResponse response = await request.send();
    // print(response.statusCode);
    if (response.statusCode == 200) {
      // print(await response.stream.bytesToString());
    } else {
      // print(response.reasonPhrase);
    }
  } catch (e) {
    // print('Failed to send status: $e');
  }
}

_updateUserStatus(int status) async {
  initLocalStorage();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String UserId = prefs.getString('UserId') ?? '';
  var headers = {'Content-Type': 'application/json'};

  dynamic shopidn = localStorage.getItem('shopid') ?? '';
  dynamic historyId = localStorage.getItem('history_id') ?? '';
  String? chatRoomIdsJson = localStorage.getItem('chatroomids');
  // print("chatRoomIdsJsonfffffff");
  // print("hello");
  // print(historyId);
  // print(chatRoomIdsJson);

  if (historyId == null ||
      historyId.toString().isEmpty ||
      historyId.toString() == 'null' ||
      historyId.toString().isEmpty) {
    // Handle empty history_id case if needed
  } else {
    // Decode the JSON string to remove backslashes
    List<dynamic> channelIdsList = jsonDecode(chatRoomIdsJson ?? '[]');

    // Re-encode the list as a JSON array
    String channelIdsJson = jsonEncode(channelIdsList);

    if (historyId == null ||
        historyId.toString().isEmpty ||
        historyId.toString() == 'null' ||
        historyId.toString().isEmpty) {
    } else {
      var request1 = http.Request(
          'POST',
          Uri.parse(
              'https://admin.connfy.at/api/update_status '));
      request1.body = json.encode({
        "status": status,
        "id": UserId,
        "shop_id": shopidn,
        "history_id": historyId,
        "channel_ids": channelIdsJson,
      });
      request1.headers.addAll(headers);
      // print(request1.body);

      http.StreamedResponse response1 = await request1.send();

      if (response1.statusCode == 200) {
        // print(response1.reasonPhrase);
        List<String> chatRoomIds = List<String>.from(channelIdsList);
        localStorage.setItem("history_id", '');
        // print('History ID deleted');
        await Future.delayed(const Duration(minutes: 10), () async {
          localStorage.removeItem('chatroomids');
          List<String> chatRoomIds = List<String>.from(channelIdsList);
          await dbMethods.deleteAllMessagesFromMultipleChatRooms(chatRoomIds);
        });

        // dbMethods.deleteAllMessagesFromMultipleChatRooms(chatRoomIds);

        // Pass the List<String> to the deleteAllMessagesFromMultipleChatRooms method
        // dbMethods.deleteAllMessagesFromMultipleChatRooms(chatRoomIds);
      } else {
        // print('RESPONSE2222');
        // print(response1.reasonPhrase);
      }
    }
  }
}

DatabaseMethods dbMethods = DatabaseMethods();
