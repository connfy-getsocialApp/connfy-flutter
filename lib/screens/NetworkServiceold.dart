import 'dart:convert';
import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:localstorage/localstorage.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../helper/shared_preference.dart';

enum NetworkStatus { Online, Offline }

class NetworkServiceold extends ChangeNotifier {
  final NetworkInfo _networkInfo = NetworkInfo();
  NetworkStatus _networkStatus = NetworkStatus.Online;
  String? wifiBSSID, wifiIPv4, wifiIPv6, wifiGatewayIP, wifiBroadcast, wifiSubmask;
//  final LocalStorage storage = LocalStorage('wifi');
  dynamic _wifiStatus = 0;
  String? wifiName = '';
  bool userIsLoggedIn = false;
  NetworkStatus networkStatusnew = NetworkStatus.Offline;
  NetworkService() {
    initLocalStorage();
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // Assuming you only care about the first result in the list
      ConnectivityResult result = results.first;

      if (result == ConnectivityResult.none) {
        _networkStatus = NetworkStatus.Offline;
        _initNetworkInfoold();
      } else {
        _networkStatus = NetworkStatus.Online;
        _initNetworkInfoold();
      }
      print("result");
      print(result);

      notifyListeners();
    });
    // _initLoginStatus();
  }

  void clearData() {
    wifiName = "";
    networkStatusnew = NetworkStatus.Offline;
    notifyListeners();
  }

  Future<void> initNetworkInfoOld() async {
    await _initNetworkInfoold();
  }

  NetworkStatus get networkStatus => _networkStatus;
  Future<void> _initLoginStatus() async {
    try {
      bool? isLoggedIn = await HelperFunctions.getUserLoggedInSharedPreference();
      userIsLoggedIn = isLoggedIn!;
      notifyListeners();
    } catch (e) {
      // developer.log('Failed to retrieve login status', error: e);
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

      // developer.log('Wifi Name: $wifiName');
      // developer.log('Wifi Name: $_wifiStatus');
      // developer.log('Wifi BSSID: $wifiBSSID');
      // developer.log('Wifi IPv4: $wifiIPv4');
      // developer.log('Wifi IPv6: $wifiIPv6');
      // developer.log('Wifi Submask: $wifiSubmask');
      // developer.log('Wifi Broadcast: $wifiBroadcast');
      // developer.log('Wifi Gateway: $wifiGatewayIP');
    } on PlatformException catch (e) {
      // developer.log('Failed to get Wifi information', error: e);
    }

    notifyListeners();
  }

  Future<void> _initNetworkInfoold() async {
    try {
      if (await Permission.locationAlways.request().isGranted) {
        wifiName = await _networkInfo.getWifiName() ?? '';
        wifiBSSID = await _networkInfo.getWifiBSSID();
      } else {
        wifiName = await _networkInfo.getWifiName() ?? '';
        wifiBSSID = await _networkInfo.getWifiBSSID() ?? '';
      }
      wifiName = "test";
      if (wifiName!.isNotEmpty) {
        await wificheck(wifiName!);
      } else {
        await wificheck('no_wifi');
      }

      // developer.log('Wifi Name: $wifiName');
      // developer.log('Wifi Name: $_wifiStatus');
      // developer.log('Wifi BSSID: $wifiBSSID');
      // developer.log('Wifi IPv4: $wifiIPv4');
      // developer.log('Wifi IPv6: $wifiIPv6');
      // developer.log('Wifi Submask: $wifiSubmask');
      // developer.log('Wifi Broadcast: $wifiBroadcast');
      // developer.log('Wifi Gateway: $wifiGatewayIP');
    } on PlatformException catch (e) {
      // developer.log('Failed to get Wifi information', error: e);
    }

    /* await storage.setItem('wifiBSSID', wifiBSSID);
    await storage.setItem('wifiIPv4', wifiIPv4);
    await storage.setItem('wifiIPv6', wifiIPv6);
    await storage.setItem('wifiSubmask', wifiSubmask);
    await storage.setItem('wifiBroadcast', wifiBroadcast);
    await storage.setItem('wifiGatewayIP', wifiGatewayIP);*/
    notifyListeners();
  }

  /*Future<void> wificheck(String? ssid) async {
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
          print(shopid);
          //  Fluttertoast.showToast(msg: 'WIFI MATCH: $status\n', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, textColor: Colors.white, fontSize: 16.0);
          // String? wifiName = ssidnew;
          localStorage.setItem('wifiName', wifiName);
          print('WIFIFIFIFI ${localStorage.getItem(wifiName)!}');
          localStorage.setItem('shopidn', shopid);
        } else {
          //  Fluttertoast.showToast(msg: 'WIFI NOT MATCH: $status\n', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, textColor: Colors.white, fontSize: 16.0);
          localStorage.setItem('wifiName', "");
          localStorage.setItem('shopidn', "");
        }
      } else {
        localStorage.setItem('wifiName', "");
        localStorage.setItem('shopidn', "");
      }
    } else {
      localStorage.setItem('wifiName', "");
      localStorage.setItem('shopidn', "");
      print(response.reasonPhrase);
    }
  }*/

  Future<void> wificheck(String? ssid) async {
    if (ssid == null) {
      // developer.log('SSID is null');
      return;
    }

    String wifiName = ssid.replaceAll('"', '');
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST', Uri.parse('https://admin.connfy.at/api/wifi_check'));
    request.body = json.encode({"ssid": wifiName});

    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String jsonData = await response.stream.bytesToString();
        Map<String, dynamic> responseData = jsonDecode(jsonData);
        // print(responseData);

        if (responseData.containsKey('data')) {
          int status = responseData['status_match'];

          if (status == 1) {
            String shopid = responseData['shop_id'].toString();
            print(shopid);

            if (localStorage != null) {
              localStorage.setItem('wifiName', wifiName);
              localStorage.setItem('shopidn', shopid);
            } else {
              // developer.log('LocalStorage is not initialized');
            }
          } else {
            localStorage?.setItem('wifiName', "");
            localStorage?.setItem('shopidn', "");
          }
        } else {
          localStorage?.setItem('wifiName', "");
          localStorage?.setItem('shopidn', "");
        }
      } else {
        localStorage?.setItem('wifiName', "");
        localStorage?.setItem('shopidn', "");
        // print(response.reasonPhrase);
      }
    } catch (e) {
      // developer.log('Error in wificheck method', error: e);
    }
  }
}
