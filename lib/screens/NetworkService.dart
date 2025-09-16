import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:localstorage/localstorage.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';


import '../constants/app_strings.dart';
import '../helper/shared_preference.dart';
import '../services/database.dart';

enum NetworkStatus { Online, Offline }

class NetworkService extends ChangeNotifier {
  final NetworkInfo _networkInfo = NetworkInfo();
  NetworkStatus _networkStatus = NetworkStatus.Online;
  String? wifiBSSID, wifiIPv4, wifiIPv6, wifiGatewayIP, wifiBroadcast, wifiSubmask;
  Timer? _wifiCheckTimer;
  dynamic _wifiStatus = 0;
  String? wifiName = '';
  bool userIsLoggedIn = false;
  NetworkStatus networkStatusnew = NetworkStatus.Offline;

  /* Stream<NetworkStatus> get networkStatusStream => _networkStatusController.stream;
  Stream<bool> get networkStatusBoolStream => networkStatusStream.map((status) {
        return status == NetworkStatus.Online;
      });*/

  // final StreamController<String?> _wifiNameController = StreamController<String?>.broadcast();
  // Stream<String?> get wifiNameStream => _wifiNameController.stream;

  NetworkService() {
    _initNetworkListeners();


  }

  NetworkStatus get networkStatus => _networkStatus;

  void _initNetworkListeners() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // Check if the results contain ConnectivityResult.none
      if (results.contains(ConnectivityResult.none)) {
        // No internet connection
        // print("No Internet Connection");
        _networkStatus = NetworkStatus.Offline;
        _updateWifiName("nowifinull");
        _updateNetworkStatus(NetworkStatus.Offline);
        localStorage.setItem('wifiName', "");
        localStorage.setItem('shopidn', "");
      } else if (results.contains(ConnectivityResult.mobile)) {

        // print('method called');
        _networkStatus = NetworkStatus.Online;
        _initNetworkInfoold();
        _updateNetworkStatus(NetworkStatus.Online);
        // Handle mobile data logic if necessary
      } else if (results.contains(ConnectivityResult.wifi)) {
        // Connected to Wi-Fi
        // print("Connected to Wi-Fi");
        _initNetworkInfoold(); // Your method to initialize Wi-Fi network details
        _networkStatus = NetworkStatus.Online;
        _updateNetworkStatus(NetworkStatus.Online);
      }

      // Broadcast the network status to listeners
      // _networkStatusController.add(_networkStatus);
      notifyListeners();
    });

    // _initLoginStatus();
  }

// Call this method when wifiName changes
  void _updateWifiName(String? newWifiName) {
    wifiName = newWifiName;
    // print("_wifiNameController $wifiName");
    //_wifiNameController.add(newWifiName);
  }

  void _updateNetworkStatus(NetworkStatus status) {
    _networkStatus = status;
    //_networkStatusController.add(status);
    notifyListeners();
  }

  @override
  void dispose() {
    _wifiCheckTimer?.cancel();
    // _wifiNameController.close();
    //_networkStatusController.close();
    super.dispose();
  }

  void clearData() {
    wifiName = "";
    networkStatusnew = NetworkStatus.Offline;
    notifyListeners();
  }

  Future<void> initNetworkInfoOld() async {
  //  _initNetworkListeners();
  _initNetworkInfoold();
    // await _();
  }

  Future<void> _initLoginStatus() async {
    try {
      bool? isLoggedIn = await HelperFunctions.getUserLoggedInSharedPreference();
      userIsLoggedIn = isLoggedIn!;
      notifyListeners();
    } catch (e) {
      // print('Failed to retrieve login status :: $e');
    }
  }

  Future<void> _initNetworkInfo() async {
    try {
      // Check if user is logged in before fetching wifi info

      if (await Permission.locationAlways.request().isGranted) {
        wifiName = await _networkInfo.getWifiName();
        wifiBSSID = await _networkInfo.getWifiBSSID();
      } else {
        wifiName = await _networkInfo.getWifiName();
        wifiBSSID = await _networkInfo.getWifiBSSID();
      }

      wifiIPv4 = await _networkInfo.getWifiIP();
      wifiIPv6 = await _networkInfo.getWifiIPv6();
      wifiSubmask = await _networkInfo.getWifiSubmask();
      wifiBroadcast = await _networkInfo.getWifiBroadcast();
      wifiGatewayIP = await _networkInfo.getWifiGatewayIP();

      debugPrint('Wifi Name: $wifiName');
      debugPrint('Wifi Name: $_wifiStatus');
      debugPrint('Wifi BSSID: $wifiBSSID');
      debugPrint('Wifi IPv4: $wifiIPv4');
      debugPrint('Wifi IPv6: $wifiIPv6');
      debugPrint('Wifi Submask: $wifiSubmask');
      debugPrint('Wifi Broadcast: $wifiBroadcast');
      debugPrint('Wifi Gateway: $wifiGatewayIP');
    } on PlatformException catch (e) {
      // print('Failed to get Wifi information:: $e');
    }

    notifyListeners();
  }

  Future<void> _initNetworkInfoold_() async {
    try {
      if (await Permission.locationAlways.request().isGranted) {
        wifiName = await _networkInfo.getWifiName() ?? '';
        wifiBSSID = await _networkInfo.getWifiBSSID();
      } else if (await Permission.location.request().isGranted) {
        wifiName = await _networkInfo.getWifiName() ?? '';
        wifiBSSID = await _networkInfo.getWifiBSSID();
      } else if (await Permission.locationWhenInUse.request().isGranted) {
        wifiName = await _networkInfo.getWifiName() ?? '';
        wifiBSSID = await _networkInfo.getWifiBSSID();
      } else {
        wifiName = await _networkInfo.getWifiName() ?? '';
        wifiBSSID = await _networkInfo.getWifiBSSID() ?? '';
      }
     //  wifiName = "FTTH-5G";
      // wifiName = "";

      if (wifiName!.isNotEmpty) {
        await wificheck(wifiName!);
        _updateWifiName(wifiName);
      }
      else {
        await wificheck('no_wifi');
        _updateWifiName('no_wifi');
      }

      // print('Wifi Name: $wifiName');
    } on PlatformException catch (e) {
      // print('Failed to get Wifi information:: $e');
    }

    notifyListeners();
  }


  Future<void> _initNetworkInfoold() async {


    try {
      // Check location permissions
      final permission = await Permission.locationWhenInUse.request();
      if (permission.isGranted) {
        wifiName = await _networkInfo.getWifiName() ?? '';
        wifiBSSID = await _networkInfo.getWifiBSSID() ?? '';
      } else if (await Permission.locationAlways.request().isGranted) {
        wifiName = await _networkInfo.getWifiName() ?? '';
        wifiBSSID = await _networkInfo.getWifiBSSID() ?? '';
      } else {
        wifiName = 'Permission not granted';
        wifiBSSID = 'Permission not granted';
      }
    // wifiName = "FTTH";
      // _currentWifiName = wifiName;
      _updateWifiName(wifiName);
      //_wifiNameController.add(_currentWifiName);
      // Check and handle Wi-Fi informationc  cf          ccfc
      if (wifiName!.isNotEmpty) {
        await wificheck(wifiName!);
        _updateWifiName(wifiName);

      } else {
        await wificheck('no_wifi');
        _updateWifiName('no_wifi');
        debugPrint('Wi-Fi 123469: $wifiName');
        debugPrint('Wi-Fi 9874: $wifiBSSID');
      }

      // Add other print statements or debug logs as needed
    } on PlatformException catch (e) {
      debugPrint('Failed to get Wi-Fi information: $e');
    } catch (e) {
      debugPrint('An unexpected error occurred: $e');
    }

    notifyListeners();
  }


  Future<void> wificheck(String? ssid) async {
    String wifiName = ssid!.replaceAll('"', '') ?? '';
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST', Uri.parse('https://admin.connfy.at/api/wifi_check'));
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
          localStorage.setItem('wifiName', wifiName);
          localStorage.setItem('shopidn', shopid);
        //  await callUpdate(responseData['shop_id']);

          await   sendStatusToServer(shopid, 1);

          //  Fluttertoast.showToast(msg: 'WIFI MATCH: $status\n', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, textColor: Colors.white, fontSize: 16.0);
          // String? wifiName = ssidnew;

        } else {
         await  _updateUserStatus(0);
          await  sendStatusToServer("", 0);
          //  Fluttertoast.showToast(msg: 'WIFI NOT MATCH: $status\n', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, textColor: Colors.white, fontSize: 16.0);
          localStorage.setItem('wifiName', "");
          localStorage.setItem('shopidn', "");
        }
      } else {
        await  _updateUserStatus(0);
        await  sendStatusToServer("", 0);
        localStorage.setItem('wifiName', "");
        localStorage.setItem('shopidn', "");
      }
    } else {
      await  _updateUserStatus(0);
      await  sendStatusToServer("", 0);
      localStorage.setItem('wifiName', "");
      localStorage.setItem('shopidn', "");
      // print(response.reasonPhrase);
    }
  }

  Future<void> sendStatusToServer(String shop_id, dynamic status) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String UserId = prefs.getString('UserId')??'';// Replace with your server URL
    try {
      var headers = {
        'Authorization': 'key=AAAAGLDkAjg:APA91bFsO9qoCm-dYTaDicJ9cHDsg8ur4HY-dqx2tRzSJrh1X7Lxg0c0pZrBEfSSnRoOHdAMUMuRe59YnWkKXFMA3BOTw5QLAqhXzUe_MQ6Bsuu71RvxGkJ5l23obQBayyOyLRJzXYk1',
        'Content-Type': 'application/json'
      };
      var request = http.Request('POST', Uri.parse('https://admin.connfy.at/check_user_status'));
      request.body = json.encode({"user_id": UserId, "shop_id": shop_id, "status": status, "connected_time": DateFormat('yyy-MM-dd HH:mm:ss').format(DateTime.now())});
      request.headers.addAll(headers);
      print(request.body);
      http.StreamedResponse response = await request.send();
      print(response.statusCode);
      if (response.statusCode == 200) {
        // print(await response.stream.bytesToString());
      } else {
        // print(response.reasonPhrase);
      }
    } catch (e) {
      // print('Failed to send status: $e');
    }
  }

  Future<void> callUpdate(dynamic shopid) async {


    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? UserId = prefs.getString('UserId');
    dynamic historyId = localStorage.getItem('history_id') ?? '';

    // Check if historyId is already stored
    if (historyId == null || historyId.toString().isEmpty) {
      var headers = {'Content-Type': 'application/json'};
      var request = http.Request('POST', Uri.parse('https://admin.connfy.at/api/update_history'));
      request.body = json.encode({"user_id": UserId, "shop_id": shopid, "history_id": ""});
      print(request.body);
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseString = await response.stream.bytesToString();

        Map<String, dynamic> responseJson = json.decode(responseString);
        // print('History response: $responseJson');

        dynamic newHistoryId = responseJson['history_id'];
        if (newHistoryId != null && newHistoryId != 'null') {
          // print('History IDneww: $newHistoryId');
          localStorage.setItem("history_id", newHistoryId.toString());

        }
      } else {

        print(response.reasonPhrase);
      }
    } else {

      print('History ID already exists: $historyId');
    }
  }
  DatabaseMethods dbMethods = DatabaseMethods();


  Future<void> _updateUserStatus(int status) async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String UserId = prefs.getString('UserId')??'';
    var headers = {'Content-Type': 'application/json'};

    dynamic shopidn = localStorage.getItem('shopid') ?? '';
    dynamic history_id = localStorage.getItem('history_id') ?? '';
    String? chatRoomIdsJson = localStorage.getItem('chatroomids');
    print("chatRoomIdsJsonfffffff");
    print(history_id);
    print(chatRoomIdsJson);


      // Decode the JSON string to remove backslashes
      List<dynamic> channelIdsList = jsonDecode(chatRoomIdsJson ?? '[]');

      // Re-encode the list as a JSON array
      String channelIdsJson = jsonEncode(channelIdsList);


        var request1 = http.Request('POST', Uri.parse('https://admin.connfy.at/api/update_status_now'));
        request1.body = json.encode({
          "status": 0,
          "id": UserId,
          "shop_id": shopidn,
          "history_id": history_id,
         "channel_ids": channelIdsJson,
        });
        request1.headers.addAll(headers);
        print(request1.body);

        http.StreamedResponse response1 = await request1.send();
       print(response1.statusCode);
        if (response1.statusCode == 200) {


          List<String> chatRoomIds = List<String>.from(channelIdsList);


          await Future.delayed(Duration(minutes: 10), () async {

            localStorage.removeItem('chatroomids');
            List<String> chatRoomIds = List<String>.from(channelIdsList);
            await dbMethods.deleteAllMessagesFromMultipleChatRooms(chatRoomIds);
          });

          // dbMethods.deleteAllMessagesFromMultipleChatRooms(chatRoomIds);

          // Pass the List<String> to the deleteAllMessagesFromMultipleChatRooms method
          // dbMethods.deleteAllMessagesFromMultipleChatRooms(chatRoomIds);

        } else {
          // print('RESPONSE2222');
          print("update");
        }


  }
}
