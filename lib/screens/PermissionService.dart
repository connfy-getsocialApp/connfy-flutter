import 'dart:io';

import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart' as loc;
class PermissionService {
  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final statuses = await [
        Permission.locationWhenInUse,
        Permission.locationAlways,
        Permission.phone,
      ].request();

      if (statuses[Permission.locationWhenInUse] == PermissionStatus.granted &&
          statuses[Permission.locationAlways] == PermissionStatus.granted &&
          statuses[Permission.phone] == PermissionStatus.granted) {
        print('All permissions granted');
      } else {
        print('Some permissions are not granted');
        // Optionally, prompt the user to grant permissions
      }
    } else if (Platform.isIOS) {
      // Handle iOS permissions
    }
  }


  Future<void> requestLocationPermission() async {
    final loc.Location location = loc.Location();
    bool _serviceEnabled = await location.serviceEnabled();

    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    final status = await Permission.location.request();
    if (status.isDenied) {
      await openAppSettings();
    } else if (status.isPermanentlyDenied) {
      // Handle permanently denied case
    }
  }


  Future<void> checkNetworkInfo() async {
    final permissionStatus = await Permission.locationWhenInUse.status;
    if (permissionStatus.isGranted) {
      // Perform network operations
      NetworkInfo _networkInfo = NetworkInfo();
      try {
        String? wifiName = await _networkInfo.getWifiName();
        print('Wi-Fi Name: $wifiName');
      } catch (e) {
        print('Failed to get Wi-Fi information: $e');
      }
    } else {
      print('Location permission is not granted.');
    }
  }

}
