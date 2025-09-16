import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'NetworkService.dart';

class NetworkController extends GetxController {
  final NetworkInfo _networkInfo = NetworkInfo();
  Rx<NetworkStatus> networkStatus = NetworkStatus.Offline.obs;
  Rx<String?> wifiName = Rx<String?>(null);
  Rx<String?> wifiBSSID = Rx<String?>(null);

  @override
  void onInit() {
    super.onInit();
    _initNetworkListeners();
  }

  void _initNetworkListeners() {
    // Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
    //   if (result == ConnectivityResult.none) {
    //     networkStatus.value = NetworkStatus.Offline;
    //     wifiName.value = "nowifinull";
    //   } else if (result == ConnectivityResult.mobile || result == ConnectivityResult.wifi) {
    //     networkStatus.value = NetworkStatus.Online;
    //     _initNetworkInfoold();
    //   }
    // });
  }

  Future<void> _initNetworkInfoold() async {
    try {
      // Request necessary permissions
      if (await Permission.locationAlways.request().isGranted || await Permission.location.request().isGranted || await Permission.locationWhenInUse.request().isGranted) {
        // Fetch network details
        wifiName.value = await _networkInfo.getWifiName();
        wifiBSSID.value = await _networkInfo.getWifiBSSID();
        // print('Wifi information: $wifiName');
      } else {
        wifiName.value = 'Permission not granted';
        wifiBSSID.value = 'Permission not granted';
        // print('Failed to get Wi-Fi information: $wifiName');
      }
    } catch (e) {
      // print('Failed to get Wi-Fi information: $e');
      wifiName.value = 'Error';
      wifiBSSID.value = 'Error';
    }
  }
}
