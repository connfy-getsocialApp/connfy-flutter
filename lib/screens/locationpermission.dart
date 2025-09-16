import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';

class MyApplloc extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApplloc> {
  loc.Location location = new loc.Location();

  @override
  void initState() {
    super.initState();
    requestLocationPermission();
  }

  Future<void> requestLocationPermission() async {
    bool _serviceEnabled;
    loc.PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == loc.PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != loc.PermissionStatus.granted && _permissionGranted != loc.PermissionStatus.grantedLimited) {
        return;
      }
    }

    if (_permissionGranted == loc.PermissionStatus.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return;
    }

    // Permission granted, you can access location services.
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Background Location Permission Needed'),
        content: Text('This app needs background location access to provide continuous tracking. Please enable it in the app settings.'),
        actions: [
          TextButton(
            onPressed: () {
              openAppSettings();
            },
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Location Permission Example'),
        ),
        body: Center(
          child: Text('Request location permission.'),
        ),
      ),
    );
  }
}
