import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:async/async.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatapp/screens/socailevents.dart';
import 'package:chatapp/screens/socialmatch.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:localstorage/localstorage.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controller/loader.dart';
import '../helper/constants.dart';
import '../services/database.dart';
import 'chats.dart';
import 'myprofile.dart';

class ChatList extends StatefulWidget {
  final authcode;

  ChatList(this.authcode);

  _MyAppState createState() => _MyAppState(this.authcode);
}

class _MyAppState extends State<ChatList> {
  var authcode;
  _MyAppState(this.authcode);
  bool _isLoading = false;
  bool listvisible_flag = true;
  bool listvisible_flag1 = false;
  bool paynow_flag1 = false;
  List<dynamic> responseData = [];
  String username = "";
  String plantid = "";
  String erporderno = "";
  String consumerId = "";
  String outputDate_to1 = "";
  String requesttype = "";
  String? UserId = "";
  String? wifiNamenew;
  bool isLoading = false;
  QuerySnapshot? searchSnapshot;
  List<dynamic> activeUsersList = [];
  DatabaseMethods databaseMethods = DatabaseMethods();
  TextEditingController searchTextEditingController = TextEditingController();
  bool haveUserSearched = false;
  int toggleindex = 0;
  int wifi_sttus = -1;
  String statuslable = "";
  dynamic colorcodelable;
  List<String> supplier_typelist = ["NEW REQUESTS", 'OLD REQUESTS'];
  Timer? _timer;
  String _connectionStatus = 'Unknown';
  late ConnectivityResult result;
  final AsyncMemoizer _memoizer = AsyncMemoizer();
  final NetworkInfo _networkInfo = NetworkInfo();
  Future<List>? _futureActiveUsersList;
  // final LocalStorage storage = new LocalStorage('wifi');
  String config_wifi = "emty";
  String connected_wifi = "empty";
  List<dynamic> _cachedData = [];
  // Other varia
  @override
  void initState() {
    activeUsersList = [];
    super.initState();
    //  retrieveWifiName();
    ///  retrive();

    //   _initNetworkInfonew();

    // _initConnectivity_new();
    // _initConnectivity();
    // startChecking();
  }

  Future<void> retrieveWifiName() async {
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST',
        Uri.parse('https://admin.connfy.at/api/wifi_details'));
    request.body = json.encode({"id": 1});
    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        Map<String, dynamic> responseData = json.decode(responseBody);

        // Ensure that the 'data' field is present and contains 'wifi_name'
        if (responseData.containsKey('data') && responseData['data'] != null) {
          Map<String, dynamic> data = responseData['data'];
          if (data.containsKey('wifi_name') && data['wifi_name'] != null) {
            String wifiName = data['wifi_name'];
            print('WiFi Name: $wifiName');
            savePost1(wifiName, wifiName);
            // Now you can use the WiFi name as needed
          } else {
            print('WiFi name not found or is null in the data');
          }
        } else {
          print('Data not found or is null in the response');
        }
      } else {
        print('Failed to retrieve WiFi name: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  savePost1(String name, String ssid) async {
    localStorage.setItem("wifiname", name);
    localStorage.setItem("SSID", ssid);
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refreshList() async {
    try {
      List<dynamic> newActiveUsersList = await _fetchListItemsnew(
        UserId,
        connected_wifi,
      );
      setState(() {
        activeUsersList = newActiveUsersList;
        activeUsersList.sort((a, b) {
          DateTime timeA = a['chat_time'] == null || a['chat_time'] == 'null'
              ? DateTime.fromMillisecondsSinceEpoch(0)
              : DateFormat("yyyy-MM-dd HH:mm:ss").parse(a['chat_time']);
          DateTime timeB = b['chat_time'] == null || b['chat_time'] == 'null'
              ? DateTime.fromMillisecondsSinceEpoch(0)
              : DateFormat("yyyy-MM-dd HH:mm:ss").parse(b['chat_time']);
          return timeB.compareTo(timeA); // Descending order, latest chats first
        });
      });
    } catch (e) {
      print("Error in refreshing list: $e");
    }
  }

  _fetchListItems(dynamic userid, String ssid) async {
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST',
        Uri.parse('https://admin.connfy.at/api/multi_api'));
    request.body = json.encode({
      "user_id": userid,
      "ssid": ssid,
      "status": 1,
    });

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      String responseString = await response.stream.bytesToString();

      List<dynamic> jsonDataList = json.decode(responseString);
      // Access the first element in the list
      dynamic jsonData1 = jsonDataList[0];

      // Access the "Campaigns" key and its value (which is a list)
      activeUsersList = jsonData1['data'];
    } else {
      print(response.reasonPhrase);
    }
  }

  /*Future<List<dynamic>> _fetchListItemsnew(dynamic userid, String config_wifi) async {
    var headers = {'Content-Type': 'application/json'};
    var url = Uri.parse('https://connfy.ragutis.com/api/multi_api');
    var body = json.encode({"status": 1, "user_id": userid, "ssid": config_wifi});

    const int maxRetries = 3;
    const Duration timeoutDuration = Duration(seconds: 3);
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        // Create a new Request object for each retry attempt
        var request = http.Request('POST', url);
        request.body = body;
        request.headers.addAll(headers);

        http.StreamedResponse response = await request.send().timeout(timeoutDuration);

        if (response.statusCode == 200) {
          String responseString = await response.stream.bytesToString();
          print(responseString);
          Map<String, dynamic> responseData = json.decode(responseString);

          if (responseData.containsKey('data')) {
            return Future.value(responseData['data']);
          } else {
            print("Error: 'data' key not found in the response");
            return Future.value([]);
          }
        } else {
          print("Error: ${response.reasonPhrase}");
          return Future.value([]);
        }
      } on TimeoutException {
        print("Error: Request timed out. Retrying (${retryCount + 1}/$maxRetries)...");
      } on http.ClientException {
        print("Error: Connection reset by peer. Retrying (${retryCount + 1}/$maxRetries)...");
      } catch (e) {
        print("API Exception: $e");
        return Future.value([]);
      }

      retryCount++;
      await Future.delayed(Duration(seconds: 2)); // Wait before retrying
    }

    return Future.value([]);
  }
*/
/*  Future<List<dynamic>> _fetchListItemsnew(dynamic userid, String config_wifi) async {
    var headers = {'Content-Type': 'application/json'};
    var url = Uri.parse('https://connfy.ragutis.com/api/multi_api');
    var body = json.encode({"status": 1, "user_id": userid, "ssid": config_wifi});

    const int maxRetries = 3;
    const Duration timeoutDuration = Duration(seconds: 10);
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        // Create a new Request object for each retry attempt
        var request = http.Request('POST', url);
        request.body = body;
        request.headers.addAll(headers);

        http.StreamedResponse response = await request.send().timeout(timeoutDuration);

        if (response.statusCode == 200) {
          String responseString = await response.stream.bytesToString();

          Map<String, dynamic> responseData = json.decode(responseString);

          if (responseData.containsKey('data')) {
            return Future.value(responseData['data']);
          } else {
            print("Error: 'data' key not found in the response");
            return Future.value([]);
          }
        } else {
          print("Error: ${response.reasonPhrase}");
          return Future.value([]);
        }
      } on TimeoutException {
        print("Error: Request timed out. Retrying (${retryCount + 1}/$maxRetries)...");
      } on http.ClientException {
        print("Error: Connection reset by peer. Retrying (${retryCount + 1}/$maxRetries)...");
      } catch (e) {
        print("API Exception: $e");
        return Future.value([]);
      }

      retryCount++;
      await Future.delayed(Duration(seconds: 2)); // Wait before retrying
    }

    return Future.value([]);
  }*/

  /*Future<List<dynamic>> _fetchListItemsnew(dynamic userid, String config_wifi) async {
    var headers = {'Content-Type': 'application/json'};
    var url = Uri.parse('https://connfy.ragutis.com/api/multi_api');
    var body = json.encode({"status": 1, "user_id": userid, "ssid": config_wifi});
    //  print(json.encode({"status": 1, "user_id": userid, "ssid": config_wifi}));

    var request = http.Request('POST', url);
    request.body = body;
    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseString = await response.stream.bytesToString();
        print(responseString);
        Map<String, dynamic> responseData = json.decode(responseString);

        if (responseData.containsKey('data')) {
          return Future.value(responseData['data']);
        } else {
          // Handle error if 'data' key is not found
          print("Error: 'data' key not found in the response");
          return Future.value([]);
        }
      } else {
        print("Error: ${response.reasonPhrase}");
        return Future.value([]);
      }
    } catch (e) {
      print("API Exception: $e");
      return Future.value([]);
    }
  }
*/

  Future<List<dynamic>> _fetchListItemsnew(
      dynamic userid, String config_wifi) async {
    var headers = {'Content-Type': 'application/json'};
    var url =
        Uri.parse('https://admin.connfy.at/api/multi_api');
    var body =
        json.encode({"status": 1, "user_id": userid, "ssid": config_wifi});
    print(body);

    const int maxRetries = 3;
    const Duration timeoutDuration = Duration(seconds: 10);
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        // Create a new Request object for each retry attempt
        var request = http.Request('POST', url);
        request.body = body;
        request.headers.addAll(headers);

        http.StreamedResponse response =
            await request.send().timeout(timeoutDuration);

        if (response.statusCode == 200) {
          String responseString = await response.stream.bytesToString();

          Map<String, dynamic> responseData = json.decode(responseString);

          if (responseData.containsKey('data')) {
            return Future.value(responseData['data']);
          } else {
            print("Error: 'data' key not found in the response");
            return Future.value([]);
          }
        } else {
          print("Error: ${response.statusCode} ${response.reasonPhrase}");
          return Future.value([]);
        }
      } on TimeoutException {
        print(
            "Error: Request timed out. Retrying (${retryCount + 1}/$maxRetries)...");
      } on http.ClientException {
        print(
            "Error: Connection reset by peer. Retrying (${retryCount + 1}/$maxRetries)...");
      } catch (e) {
        print("API Exception: $e");
        return Future.value([]);
      }

      retryCount++;
      await Future.delayed(Duration(seconds: 2)); // Wait before retrying
    }

    return Future.value([]);
  }

  /* void _startTimer() {
    const duration = Duration(seconds: 60);
    _timer = Timer.periodic(duration, (Timer timer) {
      _initConnectivity();

      // Call your method here
    });
  }*/
  void startChecking() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _initNetworkInfo();
    });
  }

  Future<void> _initConnectivity() async {
    try {
      // result = await Connectivity().checkConnectivity();
    } catch (e) {
      print(e.toString());
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _updateConnectionStatus(result);
    });

    // Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
    //   setState(() {
    //     _updateConnectionStatus(result);
    //   });
    // });
  }

  Future<void> _initConnectivity_new() async {
    try {
      // result = await Connectivity().checkConnectivity();
    } catch (e) {
      print(e.toString());
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _updateConnectionStatus_new(result);
    });

    // Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
    //   setState(() {
    //     _updateConnectionStatus_new(result);
    //   });
    // });
  }

  // Update connection status

  Future<void> _updateConnectionStatus_new(ConnectivityResult result) async {
    setState(() {
      switch (result) {
        case ConnectivityResult.wifi:
          _connectionStatus = 'WiFi';
          break;
        case ConnectivityResult.mobile:
          _connectionStatus = 'Mobile';
          break;
        case ConnectivityResult.none:
          _connectionStatus = 'None';
          break;
        default:
          _connectionStatus = 'Unknown';
          break;
      }
    });
    // Fluttertoast.showToast(msg: '_connectionStatus: $_connectionStatus\n', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, textColor: Colors.white, fontSize: 16.0);
    if (_connectionStatus == 'WiFi') {
      _initNetworkInfonew();
    }
    if (_connectionStatus == 'Mobile') {
      _initNetworkInfonew();
      //  _initNetworkInfo();
      //  await wificheck('FTTH-5G'!);
      // _updateUserStatus(0);
    } else {
      setState(() {
        wifi_sttus = 0;
      });
      // _updateUserStatus(0);
      //  await wificheck('FTTH-5G'!);
      //  await wificheck('rgtttttt fgg');
    }
    //   _initNetworkInfo();
    //  await wificheck('FTTH-5G');
    //  _initNetworkInfo();
  }

  Future<void> _initNetworkInfonew() async {
    String? wifiName = "";
    String? wifiBSSID = "";
    String? wifiIPv4 = "";
    String? wifiIPv6 = "";
    String? wifiGatewayIP = "";
    String? wifiBroadcast = "";
    String? wifiSubmask = "";
    print("afkadj");
    //   Fluttertoast.showToast(msg: 'Wifi Name: $wifiName\n', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, textColor: Colors.white, fontSize: 16.0);
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        // Request permissions as recommended by the plugin documentation:
        // https://github.com/fluttercommunity/plus_plugins/tree/main/packages/network_info_plus/network_info_plus
        if (await Permission.locationWhenInUse.request().isGranted) {
          wifiName = await _networkInfo.getWifiName();
        } else {
          wifiName = 'Unauthorized to get Wifi Name';
        }
      } else {
        wifiName = await _networkInfo.getWifiName();
      }
    } on PlatformException catch (e) {
      // developer.log('Failed to get Wifi Name', error: e);
      wifiName = 'Failed to get Wifi Name';
    }

    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        // Request permissions as recommended by the plugin documentation:
        // https://github.com/fluttercommunity/plus_plugins/tree/main/packages/network_info_plus/network_info_plus
        if (await Permission.locationWhenInUse.request().isGranted) {
          wifiBSSID = await _networkInfo.getWifiBSSID();
        } else {
          wifiBSSID = 'Unauthorized to get Wifi BSSID';
        }
      } else {
        wifiName = await _networkInfo.getWifiName();
      }
    } on PlatformException catch (e) {
      // developer.log('Failed to get Wifi BSSID', error: e);
      wifiBSSID = 'Failed to get Wifi BSSID';
    }

    try {
      wifiIPv4 = await _networkInfo.getWifiIP();
    } on PlatformException catch (e) {
      // developer.log('Failed to get Wifi IPv4', error: e);
      wifiIPv4 = 'Failed to get Wifi IPv4';
    }

    try {
      wifiIPv6 = await _networkInfo.getWifiIPv6();
    } on PlatformException catch (e) {
      // developer.log('Failed to get Wifi IPv6', error: e);
      wifiIPv6 = 'Failed to get Wifi IPv6';
    }

    try {
      wifiSubmask = await _networkInfo.getWifiSubmask();
    } on PlatformException catch (e) {
      // developer.log('Failed to get Wifi submask address', error: e);
      wifiSubmask = 'Failed to get Wifi submask address';
    }

    try {
      wifiBroadcast = await _networkInfo.getWifiBroadcast();
    } on PlatformException catch (e) {
      // developer.log('Failed to get Wifi broadcast', error: e);
      wifiBroadcast = 'Failed to get Wifi broadcast';
    }

    try {
      wifiGatewayIP = await _networkInfo.getWifiGatewayIP();
    } on PlatformException catch (e) {
      // developer.log('Failed to get Wifi gateway address', error: e);
      wifiGatewayIP = 'Failed to get Wifi gateway address';
    }
    String cleanedSsid = "";
    if (wifiName != null && wifiName.isNotEmpty) {
      cleanedSsid = wifiName!.replaceAll('"', '');

      if (cleanedSsid == config_wifi) {
        List newActiveUsersList = await _fetchListItems(UserId, "");
        setState(() {
          activeUsersList = newActiveUsersList;
        });
        setState(() {
          wifi_sttus = 1;
        });
      } else {
        // await _updateUserStatus(0);
        setState(() {
          wifi_sttus = 0;
        });
        //  await wificheck(cleanedSsid);
      }
      //  await wificheck('FTTH-5G'!);
    } else {
      setState(() {
        wifi_sttus = 1;
      });
      await _updateUserStatus(1);
      List newActiveUsersList = await _fetchListItems(UserId, "");
      setState(() {
        activeUsersList = newActiveUsersList;
      });
      cleanedSsid = "";
      //   print('wifiName is null or empty');
    }
    //  await wificheck(wifiName!);

    //Fluttertoast.showToast(msg: 'Wifi Name: $cleanedSsid\n', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, textColor: Colors.white, fontSize: 16.0);
    setState(() {
      _connectionStatus = 'Wifi Name: $wifiName\n'
          'Wifi BSSID: $wifiBSSID\n'
          'Wifi IPv4: $wifiIPv4\n'
          'Wifi IPv6: $wifiIPv6\n'
          'Wifi Broadcast: $wifiBroadcast\n'
          'Wifi Gateway: $wifiGatewayIP\n'
          'Wifi Submask: $wifiSubmask\n';
    });
  }

  Future<void> _initNetworkInfo() async {
    // await storage.ready;
    String? name = localStorage.getItem('wifiname');
    String? ssid = localStorage.getItem('SSID');
    config_wifi = localStorage.getItem('wifiname')!;

    String? wifiName = "";
    String? wifiBSSID = "";
    String? wifiIPv4 = "";
    String? wifiIPv6 = "";
    String? wifiGatewayIP = "";
    String? wifiBroadcast = "";
    String? wifiSubmask = "";

    //   Fluttertoast.showToast(msg: 'Wifi Name: $wifiName\n', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, textColor: Colors.white, fontSize: 16.0);
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        // Request permissions as recommended by the plugin documentation:
        // https://github.com/fluttercommunity/plus_plugins/tree/main/packages/network_info_plus/network_info_plus
        if (await Permission.locationWhenInUse.request().isGranted) {
          wifiName = await _networkInfo.getWifiName();
        } else {
          wifiName = 'Unauthorized to get Wifi Name';
        }
      } else {
        wifiName = await _networkInfo.getWifiName();
      }
    } on PlatformException catch (e) {
      // developer.log('Failed to get Wifi Name', error: e);
      wifiName = 'Failed to get Wifi Name';
    }

    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        // Request permissions as recommended by the plugin documentation:
        // https://github.com/fluttercommunity/plus_plugins/tree/main/packages/network_info_plus/network_info_plus
        if (await Permission.locationWhenInUse.request().isGranted) {
          wifiBSSID = await _networkInfo.getWifiBSSID();
        } else {
          wifiBSSID = 'Unauthorized to get Wifi BSSID';
        }
      } else {
        wifiName = await _networkInfo.getWifiName();
      }
    } on PlatformException catch (e) {
      // developer.log('Failed to get Wifi BSSID', error: e);
      wifiBSSID = 'Failed to get Wifi BSSID';
    }

    try {
      wifiIPv4 = await _networkInfo.getWifiIP();
    } on PlatformException catch (e) {
      // developer.log('Failed to get Wifi IPv4', error: e);
      wifiIPv4 = 'Failed to get Wifi IPv4';
    }

    try {
      wifiIPv6 = await _networkInfo.getWifiIPv6();
    } on PlatformException catch (e) {
      // developer.log('Failed to get Wifi IPv6', error: e);
      wifiIPv6 = 'Failed to get Wifi IPv6';
    }

    try {
      wifiSubmask = await _networkInfo.getWifiSubmask();
    } on PlatformException catch (e) {
      // developer.log('Failed to get Wifi submask address', error: e);
      wifiSubmask = 'Failed to get Wifi submask address';
    }

    try {
      wifiBroadcast = await _networkInfo.getWifiBroadcast();
    } on PlatformException catch (e) {
      // developer.log('Failed to get Wifi broadcast', error: e);
      wifiBroadcast = 'Failed to get Wifi broadcast';
    }

    try {
      wifiGatewayIP = await _networkInfo.getWifiGatewayIP();
    } on PlatformException catch (e) {
      // developer.log('Failed to get Wifi gateway address', error: e);
      wifiGatewayIP = 'Failed to get Wifi gateway address';
    }
    String cleanedSsid = "";
    if (wifiName != null && wifiName.isNotEmpty) {
      cleanedSsid = wifiName!.replaceAll('"', '');

      if (config_wifi == cleanedSsid) {
        List newActiveUsersList = await _fetchListItemsnew(
          UserId,
          cleanedSsid,
        );
        setState(() {
          activeUsersList = newActiveUsersList;
          activeUsersList.sort((a, b) {
            DateTime timeA = a['chat_time'] == null || a['chat_time'] == 'null'
                ? DateTime.fromMillisecondsSinceEpoch(0)
                : DateFormat("yyyy-MM-dd HH:mm:ss").parse(a['chat_time']);
            DateTime timeB = b['chat_time'] == null || b['chat_time'] == 'null'
                ? DateTime.fromMillisecondsSinceEpoch(0)
                : DateFormat("yyyy-MM-dd HH:mm:ss").parse(b['chat_time']);
            return timeB
                .compareTo(timeA); // Descending order, latest chats first
          });
        });
        setState(() {
          connected_wifi = config_wifi;
          wifi_sttus = 1;
        });
      } else {
        List newActiveUsersList = await _fetchListItemsnew(
          UserId,
          "FTT5444442345G",
        );
        setState(() {
          activeUsersList = newActiveUsersList;
        });
        setState(() {
          wifi_sttus = 0;
        });
      }
    } else {
      setState(() {
        wifi_sttus = 1;
      });
      List newActiveUsersList = await _fetchListItemsnew(
        UserId,
        'FTTH-5G',
      );
      setState(() {
        activeUsersList = newActiveUsersList;
        activeUsersList.sort((a, b) {
          DateTime timeA = a['chat_time'] == null || a['chat_time'] == 'null'
              ? DateTime.fromMillisecondsSinceEpoch(0)
              : DateFormat("yyyy-MM-dd HH:mm:ss").parse(a['chat_time']);
          DateTime timeB = b['chat_time'] == null || b['chat_time'] == 'null'
              ? DateTime.fromMillisecondsSinceEpoch(0)
              : DateFormat("yyyy-MM-dd HH:mm:ss").parse(b['chat_time']);
          return timeB.compareTo(timeA); // Descending order, latest chats first
        });
      });
      connected_wifi = "iuryrjur";
      cleanedSsid = "";
      //  print('wifiName is null or empty');
    }
    //  await wificheck(wifiName!);

    //Fluttertoast.showToast(msg: 'Wifi Name: $cleanedSsid\n', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, textColor: Colors.white, fontSize: 16.0);
    setState(() {
      _connectionStatus = 'Wifi Name: $wifiName\n'
          'Wifi BSSID: $wifiBSSID\n'
          'Wifi IPv4: $wifiIPv4\n'
          'Wifi IPv6: $wifiIPv6\n'
          'Wifi Broadcast: $wifiBroadcast\n'
          'Wifi Gateway: $wifiGatewayIP\n'
          'Wifi Submask: $wifiSubmask\n';
    });
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    setState(() {
      switch (result) {
        case ConnectivityResult.wifi:
          _connectionStatus = 'WiFi';
          break;
        case ConnectivityResult.mobile:
          _connectionStatus = 'Mobile';
          break;
        case ConnectivityResult.none:
          _connectionStatus = 'None';
          break;
        default:
          _connectionStatus = 'Unknown';
          break;
      }
    });
    // Fluttertoast.showToast(msg: '_connectionStatus: $_connectionStatus\n', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, textColor: Colors.white, fontSize: 16.0);
    if (_connectionStatus == 'WiFi') {
      _initNetworkInfo();
    }
    if (_connectionStatus == 'Mobile') {
      //  _initNetworkInfo();
      await wificheck('FTTH-5G'!);
      // _updateUserStatus(0);
    } else {
      setState(() {
        wifi_sttus = 0;
      });
      // _updateUserStatus(0);
      //  await wificheck('FTTH-5G'!);
      //  await wificheck('rgtttttt fgg');
    }
    //   _initNetworkInfo();
    //  await wificheck('FTTH-5G');
    //  _initNetworkInfo();
  }

  Future retrive() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Return String
    UserId = prefs.getString('UserId');
    print(config_wifi);
    _refreshList();
    _initNetworkInfo();

    _timer =
        Timer.periodic(Duration(seconds: 10), (Timer t) => _initNetworkInfo());
  }

  Future<void> wificheck(String ssid) async {
    if (ssid == null || ssid.isEmpty) {
      print('SSID is null or empty');
      return;
    }

    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST',
        Uri.parse('https://admin.connfy.at/api/wifi_check'));
    request.body = json.encode({"ssid": ssid});
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      String jsonData = await response.stream.bytesToString();
      Map<String, dynamic> responseData = jsonDecode(jsonData);
      print(responseData);
      setState(() {
        wifi_sttus = responseData['status_match'];
      });

      print(wifi_sttus);

      if (wifi_sttus == 0) {
        //   _fetchListItems(UserId);
      } else {}

      String mobileDeviceId = responseData['data'];
      print(mobileDeviceId);
    } else {
      print(response.reasonPhrase);
    }
  }

  createChatroomAndStartConversation(
      String uid, String username, String userid, dynamic imageurl) {
    if (uid != Constants.myName) {
      String chatRoomId = getChatRoomId(uid, Constants.myName);
      List<String> users = [Constants.myName, uid];
      Map<String, dynamic> chatRoomMap = {
        "chatroomId": chatRoomId,
        "users": users,
      };
      databaseMethods.addChatRoom(chatRoomMap, chatRoomId);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Chat(chatRoomId, uid, username, "1", userid,
                  imageurl, Constants.myName, "")));
    } else {
      print("you cannot send message to yourself");
    }
  }

  getChatRoomId(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "$b\_$a";
    } else {
      return "$a\_$b";
    }
  }

  void parseResponseData(Map<String, dynamic> userData) {
    // Extract data from responseData and handle it as needed
    // For example:
    String userId = userData['Messsage'];

    // Access more fields as needed

    print('User ID: $userId');
  }

  List<bool> _selections = List.generate(2, (_) => false);
  var appBarHeight = AppBar().preferredSize.height;
  var _popupMenuItemIndex = 0;
  Color _changeColorAccordingToMenuItem = Colors.red;
  String _onDropDownChanged_stype(String val) {
    var prefix;
    if (val.length > 0) {
      prefix = val;
    } else {
      prefix = "Select Requests";
    }

    return prefix;
  }

  String formatChatTime(String chatTime) {
    if (chatTime == null || chatTime == 'null') {
      return "";
    }

    DateTime messageDate = DateTime.parse(chatTime);
    DateTime now = DateTime.now();

    // Check if the message was sent today
    if (messageDate.year == now.year &&
        messageDate.month == now.month &&
        messageDate.day == now.day) {
      return DateFormat.jm().format(messageDate); // Show time (e.g., 2:30 PM)
    }

    // Check if the message was sent yesterday
    DateTime yesterday = now.subtract(Duration(days: 1));
    if (messageDate.year == yesterday.year &&
        messageDate.month == yesterday.month &&
        messageDate.day == yesterday.day) {
      return 'Yesterday';
    }

    // Otherwise, show the date (e.g., Jan 1, 2023)
    return DateFormat.yMMMd().format(messageDate);
  }

  Widget getAppBottomView() {
    return Container(
      padding: const EdgeInsets.only(left: 5, bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Image.asset(
            "assets/images/confywhite.png",
            fit: BoxFit.contain,
            height: 58,
          ),
          PopupMenuButton(
            color: Colors.blue,
            itemBuilder: (context) {
              return [
                const PopupMenuItem(
                  value: 'pro',
                  child: Text(
                    'My Profile',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ];
            },
            onSelected: (String value) {
              if (value == 'pro') {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => MyProfilePage("1",)));
              }
              print('You Click on po up menu item');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        loadUi(),
        _isLoading ? Loader(loadingTxt: 'Please wait..') : Container()
      ],
    );
  }

  @override
  Widget loadUi() {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            leading: Container(),
            backgroundColor: Color(0xfff5f5f5),
            bottom: PreferredSize(
                child: getAppBottomView(),
                preferredSize: const Size.fromHeight(40.0)),
          ),
          body: wifi_sttus == 1
              ? Container(
                  // padding: const EdgeInsets.all(3.0),
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  color: Color(0xffe5e5e5),

                  child: Column(
                    children: <Widget>[
                      /*  Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 5.0),
                          child: Text(
                            'Connected Wifi: $_connectionStatus',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.green,
                              fontWeight: FontWeight.w300,
                            ),
                          )),*/
                      /*    Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 5.0),
                        child: Text(
                          'Connected Wifi: $wifiNamenew',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.green,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),*/
                      /* const SizedBox(
                        height: 20,
                      ),*/

                      // Here, default theme colors are used for activeBgColor, activeFgColor, inactiveBgColor and inactiveFgColor

                      Visibility(
                        visible: true,
                        child: Expanded(
                          child: RefreshIndicator(
                            onRefresh: _refreshList,
                            child: ListView.builder(
                              scrollDirection: Axis.vertical,
                              itemCount: activeUsersList.length,
                              itemBuilder: (ctx, index) {
                                return activeUsersList[index]['chat_id'] ==
                                        Constants.myName
                                    ? Container(
                                        /*padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 5.0),
                                        child: Text(
                                          'Connected Wifi: $_connectionStatus',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.green,
                                            fontWeight: FontWeight.w300,
                                          ),
                                        )*/
                                        )
                                    : GestureDetector(
                                        child: Container(
                                          margin: const EdgeInsets.fromLTRB(
                                              0, 0, 0, 1),
                                          color: Colors.transparent,
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 0.0, horizontal: 0.0),
                                            child: Column(
                                              children: <Widget>[
                                                Container(
                                                  margin: const EdgeInsets
                                                      .symmetric(
                                                      vertical: 0.0,
                                                      horizontal: 0.0),
                                                  child: Container(
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(0),
                                                        bottomRight:
                                                            Radius.circular(0),
                                                        bottomLeft:
                                                            Radius.circular(0),
                                                        topRight:
                                                            Radius.circular(0),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: <Widget>[
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      0.0,
                                                                  vertical:
                                                                      5.0),
                                                          height: 80,
                                                          width: 80,
                                                          child:
                                                              CachedNetworkImage(
                                                            imageUrl:
                                                                activeUsersList[
                                                                        index][
                                                                    'horoscope_image_url'],
                                                            placeholder: (context,
                                                                    url) =>
                                                                Image.asset(
                                                                    'assets/images/photo.png',
                                                                    fit: BoxFit
                                                                        .contain),
                                                            errorWidget:
                                                                (context, url,
                                                                    error) {
                                                              print(
                                                                  "Error loading image: $error");
                                                              return Image.asset(
                                                                  'assets/images/photo.png',
                                                                  fit: BoxFit
                                                                      .contain);
                                                            },
                                                            fit: BoxFit.contain,
                                                            width: 80,
                                                            height: 80,
                                                          ),
                                                        ),
                                                        Flexible(
                                                          flex: 2,
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        3.0,
                                                                    vertical:
                                                                        5.0),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: <Widget>[
                                                                Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: <Widget>[
                                                                    Container(
                                                                      width: MediaQuery.of(context)
                                                                              .size
                                                                              .width /
                                                                          2,
                                                                      child:
                                                                          Text(
                                                                        activeUsersList[index]['name'] ==
                                                                                null
                                                                            ? ""
                                                                            : activeUsersList[index]['name'],
                                                                        style: GoogleFonts.poppins(
                                                                            fontSize:
                                                                                15,
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                            color: Colors.black87),
                                                                      ),
                                                                    ),
                                                                    Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .end,
                                                                      children: <Widget>[
                                                                        Text(
                                                                          activeUsersList[index]['chat_time'] == null || activeUsersList[index]['chat_time'] == 'null'
                                                                              ? ""
                                                                              : formatChatTime(activeUsersList[index]['chat_time']),
                                                                          style: GoogleFonts.poppins(
                                                                              color: Colors.blue,
                                                                              fontWeight: FontWeight.w400,
                                                                              fontSize: 14),
                                                                        ),
                                                                        const SizedBox(
                                                                          width:
                                                                              5,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                                Padding(
                                                                  padding: const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          10.0,
                                                                      vertical:
                                                                          5.0),
                                                                  child: Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceBetween,
                                                                    children: <Widget>[
                                                                      Container(
                                                                        padding: const EdgeInsets
                                                                            .symmetric(
                                                                            horizontal:
                                                                                3.0,
                                                                            vertical:
                                                                                5.0),
                                                                        child:
                                                                            Text(
                                                                          activeUsersList[index]['chat_message'] == null || activeUsersList[index]['chat_message'] == 'null'
                                                                              ? ""
                                                                              : activeUsersList[index]['chat_message'],
                                                                          style:
                                                                              GoogleFonts.poppins(
                                                                            fontSize:
                                                                                14,
                                                                            color:
                                                                                Colors.black54,
                                                                            fontWeight:
                                                                                FontWeight.w400,
                                                                          ),
                                                                          overflow:
                                                                              TextOverflow.ellipsis, // Adds ellipsis for long text
                                                                          maxLines:
                                                                              1, // Limits the text to one line
                                                                        ),
                                                                      ),
                                                                      const SizedBox(
                                                                        width:
                                                                            5,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                )
                                                                /* Row(
                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                  children: <Widget>[
                                                                    Container(
                                                                      padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 5.0),
                                                                      child: Text(
                                                                        activeUsersList[index]['chat_message'] == null || activeUsersList[index]['chat_message'] == 'null'
                                                                            ? ""
                                                                            : activeUsersList[index]['chat_message'],
                                                                        style: GoogleFonts.poppins(
                                                                          fontSize: 14,
                                                                          color: Colors.black54,
                                                                          fontWeight: FontWeight.w400,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 5,
                                                                    ),
                                                                  ],
                                                                ),*/
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        onTap: () {
                                          createChatroomAndStartConversation(
                                            activeUsersList[index]['chat_id'],
                                            activeUsersList[index]['name'],
                                            activeUsersList[index]['id']
                                                .toString(),
                                            activeUsersList[index]
                                                    ['horoscope_image_url']
                                                .toString(),
                                          );
                                        },
                                      );
                              },
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                )
              : wifi_sttus == -1
                  ? Container()
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          /* Container(
                              padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 5.0),
                              child: Text(
                                'Connected Wifi: $_connectionStatus',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w300,
                                ),
                              )),*/
                          Container(
                            height: 200,
                            width: 200,
                            padding: const EdgeInsets.fromLTRB(35, 10, 35, 10),
                            /*decoration: BoxDecoration(
                color: themeColor,
                shape: BoxShape.circle,
              ),*/
                            child: Image.asset(
                              "assets/images/nowifi.png",
                              fit: BoxFit.contain,
                            ),
                          ),
                          // SizedBox(height: screenHeight * 0.1),
                          Text(
                            "Please #getsocial! You are not connected. ",
                            style: GoogleFonts.poppins(
                              color: Colors.black45,
                              fontWeight: FontWeight.w500,
                              fontSize: 20,
                            ),
                          ),
                          //   SizedBox(height: screenHeight * 0.01),
                          /*  Text(
              "Kindly await approval from the  manager \n before proceeding further.",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w400,
                fontSize: 17,
              ),
            ),*/

                          Text(
                            "Please check your Wi-Fi connection.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w400,
                              fontSize: 20,
                            ),
                          ),
                          //  SizedBox(height: screenHeight * 0.06),
                          /* Flexible(
              child: HomeButton(
                title: 'Home',
                onTap: () {
                  Navigator.pushReplacement(
                      context, MaterialPageRoute(builder: (context) =>  Dashboard()));
                },
              ),
            ),*/
                        ],
                      ),
                    ),
          bottomNavigationBar: Container(
              color: const Color(0xfff5f5f5),
              height: 80,
              // padding: EdgeInsets.all(5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                //crossAxisAlignment: CrossAxisAlignment.s,
                children: [
                  // ignore: deprecated_member_use
                  Container(
                    child: Material(
                      color: const Color(0xfff5f5f5),
                      child: InkWell(
                        //  splashColor: Colors.green,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => ChatList("1")));
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            IconButton(
                              color: Colors.blue,
                              onPressed: () {},
                              icon: SvgPicture.asset(
                                'assets/icons/chat.svg',
                                colorFilter: ColorFilter.mode(
                                    Colors.blue, BlendMode.srcIn),
                              ),
                            ), // <-- Icon
                            const Text(
                              "Chats",
                              style:
                                  TextStyle(color: Colors.blue, fontSize: 12),
                            ), // <-- Text
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 30,
                  ),
                  Container(
                    child: Material(
                      color: const Color(0xfff5f5f5),
                      child: InkWell(
                        // splashColor: Colors.green,
                        onTap: () {
                          //  Navigator.of(context).push(MaterialPageRoute(builder: (context) => SocilamatchList("2")));
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            IconButton(
                              color: Colors.blue,
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) =>
                                        SocilamatchList("2")));
                              },
                              icon: SvgPicture.asset(
                                'assets/icons/social-match.svg',
                                colorFilter: ColorFilter.mode(
                                    Colors.grey, BlendMode.srcIn),
                              ),
                            ),
                            const Text(
                              "Social Match",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
                            ), // <-- Text
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 30,
                  ),
                  Container(
                    child: Material(
                      color: const Color(0xfff5f5f5),
                      child: InkWell(
                        // splashColor: Colors.green,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => EventsList()));
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            IconButton(
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => EventsList()));
                              },
                              icon: SvgPicture.asset(
                                'assets/icons/social-event.svg',
                                colorFilter: ColorFilter.mode(
                                    Colors.grey, BlendMode.srcIn),
                              ),
                            ),
                            const Text(
                              "Social Events",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
                            ), // <-- Text
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ))),
    );
  }

/*  Future<void> _fetchListItems(dynamic userid) async {
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST', Uri.parse('https://connfy.ragutis.com/api/online_users'));
    request.body = json.encode({"user_id": userid});
    request.headers.addAll(headers);
    print(json.encode({"user_id": userid}));

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      String responseString = await response.stream.bytesToString();
      Map<String, dynamic> responseData = json.decode(responseString);

      if (responseData.containsKey('data')) {
        setState(() {
          activeUsersList = responseData['data'];
        });
      } else {
        // Handle error if 'data' key is not found
        print("Error: 'data' key not found in the response");
      }
    } else {
      print(response.reasonPhrase);
    }
  }*/

  Future<void> _updateUserStatus(int status) async {
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST',
        Uri.parse('https://admin.connfy.at/api/update_status'));
    request.body = json.encode({"status": status, "id": UserId});
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      //  await _fetchListItems(UserId);
      print(await response.stream.bytesToString());
    } else {
      print(response.reasonPhrase);
    }
  }
}

class CustomShape extends CustomClipper<Path> {
  @override
  getClip(Size size) {
    double height = size.height;
    double width = size.width;
    var path = Path();
    path.lineTo(0, height - 60);
    path.quadraticBezierTo(width / 2, height, width, height - 60);
    path.lineTo(width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper oldClipper) {
    return true;
  }
}

class ExpandableText extends StatefulWidget {
  const ExpandableText(
    this.text, {
    this.trimLines = 2,
  });

  final String text;
  final int trimLines;

  @override
  ExpandableTextState createState() => ExpandableTextState();
}

class ExpandableTextState extends State<ExpandableText> {
  bool _readMore = true;
  void _onTapLink() {
    setState(() => _readMore = !_readMore);
  }

  @override
  Widget build(BuildContext context) {
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);
    final colorClickableText = Colors.blue;
    final widgetColor = Colors.black;
    TextSpan link = TextSpan(
        text: _readMore ? "... read more" : " read less",
        style: TextStyle(
          color: colorClickableText,
        ),
        recognizer: TapGestureRecognizer()..onTap = _onTapLink);
    Widget result = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        assert(constraints.hasBoundedWidth);
        final double maxWidth = constraints.maxWidth;
        // Create a TextSpan with data
        final text = TextSpan(
          text: widget.text,
        );
        // Layout and measure link
        TextPainter textPainter = TextPainter(
          text: link,
          //textDirection: TextDirection.rtl, //better to pass this from master widget if ltr and rtl both supported
          maxLines: widget.trimLines,
          ellipsis: '...',
        );
        textPainter.layout(minWidth: constraints.minWidth, maxWidth: maxWidth);
        final linkSize = textPainter.size;
        // Layout and measure text
        textPainter.text = text;
        textPainter.layout(minWidth: constraints.minWidth, maxWidth: maxWidth);
        final textSize = textPainter.size;
        // Get the endIndex of data
        int? endIndex;
        final pos = textPainter.getPositionForOffset(Offset(
          textSize.width - linkSize.width,
          textSize.height,
        ));
        endIndex = textPainter.getOffsetBefore(pos.offset);
        var textSpan;
        if (textPainter.didExceedMaxLines) {
          textSpan = TextSpan(
            text: _readMore ? widget.text.substring(0, endIndex) : widget.text,
            style: TextStyle(
              color: widgetColor,
            ),
            children: <TextSpan>[link],
          );
        } else {
          textSpan = TextSpan(
            text: widget.text,
          );
        }
        return RichText(
          softWrap: true,
          overflow: TextOverflow.clip,
          text: textSpan,
        );
      },
    );
    return result;
  }
}
